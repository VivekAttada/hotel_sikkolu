# Hotel Sikkolu

A Rails 8 application for daily hotel operations — grocery management, daily checklists, inventory quantity tracking, and team information.

## Requirements

- **Ruby** 3.4.10
- **Rails** 8.1
- **SQLite3** (default database)

## Setup

```bash
cd hotel_sikkolu
source ~/.rvm/scripts/rvm && rvm use 3.4.10
bundle install
yarn install
yarn build:css
bin/rails db:setup
```

## Run the app

```bash
bin/dev
# or
bin/rails server
```

Open http://localhost:3000

## Four Tabs

### 1. Grocery
Upload an Excel/CSV sheet with grocery details. All rows are stored in the `grocery_items` table. Each new upload replaces the previous list.

**Expected columns:** Item Name, Category, Quantity, Unit, Price, Supplier, Notes

### 2. Checklist
Daily checklist with checkboxes. Checked status is saved per day in `daily_checklists` and `checklist_entries`.

### 3. Quantities
Upload today's opening quantities from Excel. Record expenses during the day — each expense subtracts from available quantity. Repeat daily with a new upload.

**Expected columns:** Item Name, Quantity, Unit

### 4. Hotel Info
Team profiles for Bindu, Harish, Manoj, and Abhishek with photos and descriptions.

## Database Schema

```
checklist_tasks ──< checklist_entries >── daily_checklists
inventory_items ──< quantity_expenses
daily_inventories ──< inventory_items
grocery_items (standalone)
team_members (with Active Storage photo)
```

## Sample Data

Sample CSV files for testing uploads are in `sample_data/`:
- `grocery_sample.csv`
- `quantity_sample.csv`
# hotel_sikkolu
