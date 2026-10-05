#!/usr/bin/env python3
"""Populate an SCCA participation report from Orbits timing data.

Takes two inputs that complement each other:

  * the Orbits results PDF  - finishing order, car number, driver name, class
  * the Orbits CSV export   - member ID, vehicle make/model, canonical name spelling

The two are joined on driver name. The CSV is authoritative for name spelling
and for the first/last split, which cannot be inferred reliably from the PDF
(multi-word surnames such as "Avendano Diaz" and "Caberol Prat" defeat any
naive split on whitespace).
"""

import re
import csv
import logging
import argparse
from openpyxl import load_workbook
from openpyxl.worksheet.protection import SheetProtection

logging_format = '%(asctime)s - %(levelname)s - %(message)s'
logging.basicConfig(level=logging.INFO, format=logging_format)

DEFAULT_SHEET_NAME = 'xx-xxxx-123456 Participation'

# Worksheet layout. Data begins directly under the header row; a legend block
# ("Bold-headed columns are required") sits below the data area, separated by
# LEGEND_GAP blank rows, and is pushed down as participants are written.
HEADER_ROW = 1
DATA_START_ROW = 2
LEGEND_GAP = 2
LEGEND_MARKER = 'Bold-headed columns are required'

# Only the bold-headed columns are required by the sanctioning body. Passing
# Rules (U) and Satisfactory (V) are also required but are not present in
# either input, so they are left blank for manual entry.
COL_FIRST_NAME = 'A'
COL_LAST_NAME = 'B'
COL_MEMBER_ID = 'C'
COL_POS = 'D'
COL_PIC = 'E'
COL_MAKE_MODEL = 'P'
COL_CLASS = 'W'

WRITE_COLUMNS = [
    COL_FIRST_NAME, COL_LAST_NAME, COL_MEMBER_ID,
    COL_POS, COL_PIC, COL_MAKE_MODEL, COL_CLASS,
]

TIME_PATTERN = re.compile(r'^\d+:\d+\.\d+$')


def normalize_name(name):
    """Key for joining PDF names to CSV names.

    Case and internal whitespace vary between the two exports ("Joseph
    Desantis" in the PDF vs "Joseph DeSantis" in the CSV), so both are folded
    away before comparison.
    """
    return ' '.join(name.lower().split())


def load_driver_index(csv_path):
    """Build a driver lookup from the Orbits CSV export.

    The export carries one row per driver per segment (Saturday and Sunday),
    so rows are collapsed to one entry per driver. Returns the lookup plus the
    set of class names, which the PDF parser needs to find where a driver's
    name ends and their class begins.
    """
    drivers = {}
    classes = set()
    try:
        with open(csv_path, newline='', encoding='utf-8-sig') as fh:
            for row in csv.DictReader(fh):
                first = row.get('First Name', '').strip()
                last = row.get('Last Name', '').strip()
                if not first and not last:
                    continue
                cls = row.get('Class', '').strip()
                if cls:
                    classes.add(cls)
                drivers[normalize_name(f'{first} {last}')] = {
                    'first': first,
                    'last': last,
                    'member_id': row.get('Member #', '').strip(),
                    'make_model': row.get('Vehicle Make/Model', '').strip(),
                    'class': cls,
                    'number': row.get('No.', '').strip(),
                }
    except OSError as e:
        logging.error(f"Cannot read CSV '{csv_path}': {e}")
        raise

    logging.info(f'Loaded {len(drivers)} drivers from CSV across {len(classes)} classes.')
    return drivers, classes


def split_name_and_class(middle, classes):
    """Separate a driver name from the class that follows it.

    The PDF renders both as free text with no delimiter, and class names vary
    in word count ("Max 2" vs "Club Spec Mustang"), so the class is matched as
    a suffix against the known class names, longest first.
    """
    for cls in sorted(classes, key=len, reverse=True):
        if middle.lower().endswith(cls.lower()):
            return middle[:-len(cls)].strip(), cls
    return middle, None


def extract_results(pdf_path, classes):
    """Pull finishing position, car number, driver name and class from the PDF."""
    import pdfplumber

    results = []
    try:
        with pdfplumber.open(pdf_path) as pdf:
            for page in pdf.pages:
                text = page.extract_text() or ''
                for line in text.splitlines():
                    tokens = line.strip().split()
                    if len(tokens) < 6 or not tokens[0].isdigit():
                        continue
                    time_idx = next(
                        (i for i, t in enumerate(tokens) if TIME_PATTERN.match(t)), None
                    )
                    if time_idx is None or time_idx < 3:
                        continue
                    middle = ' '.join(tokens[2:time_idx])
                    name, cls = split_name_and_class(middle, classes)
                    if cls is None:
                        logging.warning(
                            f'Could not identify a class in "{middle}" - '
                            'the driver name may absorb it.'
                        )
                    results.append({
                        'pos': int(tokens[0]),
                        'number': tokens[1],
                        'name': name,
                        'class': cls or '',
                        'best_time': tokens[time_idx],
                    })
    except Exception as e:
        logging.error(f"Error parsing PDF '{pdf_path}': {e}")
        raise

    logging.info(f'Found {len(results)} result entries in PDF.')
    return results


def build_participants(results, drivers):
    """Join PDF results to CSV drivers, collapse duplicates, assign POS and PIC.

    A driver who enters more than one car appears once per entry in the PDF.
    The participation report lists each person once, so only their best finish
    is kept and POS is renumbered contiguously from 1.
    """
    best = {}
    for entry in results:
        key = normalize_name(entry['name'])
        if key not in best or entry['pos'] < best[key]['pos']:
            if key in best:
                logging.info(
                    f"{entry['name']} has multiple entries; keeping best finish."
                )
            best[key] = entry
        else:
            logging.info(
                f"{entry['name']} has multiple entries; keeping best finish."
            )

    participants = []
    unmatched = []
    missing_member_id = []

    for key, entry in sorted(best.items(), key=lambda kv: kv[1]['pos']):
        driver = drivers.get(key)
        if driver is None:
            unmatched.append(entry['name'])
            continue

        if driver['class'] and entry['class'] and driver['class'] != entry['class']:
            logging.warning(
                f"Class mismatch for {driver['first']} {driver['last']}: "
                f"PDF says '{entry['class']}', CSV says '{driver['class']}'. "
                'Using the PDF value.'
            )

        if not driver['member_id']:
            missing_member_id.append(f"{driver['first']} {driver['last']}")

        participants.append({
            'first': driver['first'],
            'last': driver['last'],
            'member_id': driver['member_id'],
            'make_model': driver['make_model'],
            'class': entry['class'] or driver['class'],
            'pdf_pos': entry['pos'],
        })

    # POS is renumbered so it stays contiguous after duplicates are collapsed.
    # PIC is each driver's rank within their own class, in finishing order.
    class_counts = {}
    for index, p in enumerate(participants, start=1):
        p['pos'] = index
        class_counts[p['class']] = class_counts.get(p['class'], 0) + 1
        p['pic'] = class_counts[p['class']]

    for name in unmatched:
        logging.warning(f'No CSV entry for "{name}" - omitted from the report.')
    if missing_member_id:
        logging.warning(
            f'{len(missing_member_id)} participant(s) have no member ID in the '
            f'CSV; column {COL_MEMBER_ID} left blank for: '
            + ', '.join(missing_member_id)
        )

    logging.info(f'Prepared {len(participants)} participants for the report.')
    return participants


def find_legend_row(sheet):
    """Locate the legend block that sits below the data area."""
    for row in range(1, sheet.max_row + 1):
        value = sheet[f'A{row}'].value
        if isinstance(value, str) and value.strip().startswith(LEGEND_MARKER):
            return row
    return None


def as_member_id(value):
    """Member IDs are numeric, but preserve any that carry a leading zero."""
    if value.isdigit() and not value.startswith('0'):
        return int(value)
    return value


def update_excel_template(
    pdf_path, csv_path, template_path, output_path,
    sheet_name=DEFAULT_SHEET_NAME, sheet_password=None
):
    drivers, classes = load_driver_index(csv_path)
    if not drivers:
        logging.error('No drivers found in CSV. Check the export format.')
        return

    results = extract_results(pdf_path, classes)
    if not results:
        logging.error('No results extracted from PDF. Check the report format.')
        return

    participants = build_participants(results, drivers)
    if not participants:
        logging.error('No participants could be matched between the PDF and CSV.')
        return

    try:
        book = load_workbook(template_path)
    except Exception as e:
        logging.error(f"Cannot open template '{template_path}': {e}")
        raise

    if sheet_name not in book.sheetnames:
        logging.error(f"Sheet '{sheet_name}' not found. Available: {book.sheetnames}")
        raise KeyError(f"Sheet '{sheet_name}' not found.")

    sheet = book[sheet_name]

    if sheet.protection.sheet:
        logging.info('Unprotecting sheet.')
        sheet.protection = SheetProtection(sheet=False)

    # Make room so the legend block is never overwritten.
    legend_row = find_legend_row(sheet)
    if legend_row is None:
        logging.warning(
            'Legend block not found; writing participants without adjusting '
            'the sheet below the data area.'
        )
        last_data_row = DATA_START_ROW + len(participants) - 1
    else:
        capacity = legend_row - LEGEND_GAP - DATA_START_ROW
        if len(participants) > capacity:
            extra = len(participants) - capacity
            logging.info(f'Inserting {extra} row(s) to fit all participants.')
            sheet.insert_rows(legend_row - LEGEND_GAP, extra)
            legend_row += extra
        last_data_row = legend_row - LEGEND_GAP - 1

    for row in range(DATA_START_ROW, last_data_row + 1):
        for col in WRITE_COLUMNS:
            sheet[f'{col}{row}'] = None

    for i, p in enumerate(participants):
        row = DATA_START_ROW + i
        sheet[f'{COL_FIRST_NAME}{row}'] = p['first']
        sheet[f'{COL_LAST_NAME}{row}'] = p['last']
        sheet[f'{COL_MEMBER_ID}{row}'] = as_member_id(p['member_id']) if p['member_id'] else None
        sheet[f'{COL_POS}{row}'] = p['pos']
        sheet[f'{COL_PIC}{row}'] = p['pic']
        sheet[f'{COL_MAKE_MODEL}{row}'] = p['make_model']
        sheet[f'{COL_CLASS}{row}'] = p['class']

    if sheet_password:
        logging.info('Re-protecting sheet.')
        sheet.protection = SheetProtection(password=sheet_password, sheet=True)

    try:
        book.save(output_path)
        logging.info(f"Saved report to '{output_path}'")
    except Exception as e:
        logging.error(f"Error saving to '{output_path}': {e}")
        raise

    logging.info(
        'Columns Passing Rules and Satisfactory are required but are not '
        'present in either input - fill them in before submitting.'
    )


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Populate participation report')
    parser.add_argument('pdf_input', help='Orbits results PDF path')
    parser.add_argument('csv_input', help='Orbits CSV export path')
    parser.add_argument('excel_template', help='Excel template path')
    parser.add_argument('output_file', help='Output Excel path')
    parser.add_argument('--sheet-name', default=DEFAULT_SHEET_NAME, help='Worksheet name')
    parser.add_argument('--sheet-password', default=None, help='Worksheet password')
    args = parser.parse_args()
    update_excel_template(
        args.pdf_input,
        args.csv_input,
        args.excel_template,
        args.output_file,
        sheet_name=args.sheet_name,
        sheet_password=args.sheet_password
    )
