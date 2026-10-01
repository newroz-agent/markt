# Zêrîn — New Marketplace Categories: Gold, Suits, Music, Supermarket, Deals
### Paste into Claude Code. Pure category-tree/data change — no new screens, no new tables, no migration risk of the kind Steps B–D had.

---

## Why this is low-risk
The category grid, subcategory screens, filters, and the Sell flow's catalog search
already read categories dynamically from the `categories` table (self-referencing
`parent_id`). Adding rows there should require little to no Flutter code change — the
UI is already category-agnostic.

## Rules for this pass
- **Audit first** (same discipline as every step so far): read the current
  `categories` table rows before inserting anything, to see the existing top-level
  categories, their icon/image column conventions, and whether any of these new ones
  already exist as subcategories somewhere (e.g. check if "Uhren & Schmuck" or
  "Mode Herren" already exist before adding overlapping new top-level categories).
- Match the existing category data shape exactly (same columns, same icon/image
  convention) — don't invent a new schema for these.

---

## 1. Gold & Schmuck
If a "Uhren & Schmuck" category already exists, add these as subcategories there
instead of creating a new overlapping top-level category (check first). If it doesn't
exist yet, add a new top-level category with these subcategories:
- Goldschmuck
- Silberschmuck
- Eheringe
- Antiker Schmuck

## 2. Anzüge & Formal Wear
Add as a **subcategory** under the existing "Mode Herren" category (don't create a new
top-level fashion category — check the exact existing category name first).

## 3. Musikinstrumente (new top-level)
Subcategories, explicitly including instruments relevant to the Kurdish/Middle Eastern
community, not just Western ones:
- Tasteninstrumente
- Saiteninstrumente (inkl. Saz/Bağlama, Oud)
- Schlaginstrumente (inkl. Def)
- Blasinstrumente (inkl. Zurna)
- Zubehör & Noten

## 4. Supermarkt & Lebensmittel
If a food/grocery category already exists (check for something like "Lebensmittel &
Süßes"), expand it. Otherwise add a new top-level category:
- Frische Lebensmittel
- Getränke
- Süßwaren
- Gewürze & Importwaren (explicitly cover kurdische/orientalische Spezialitäten here)

## 5. "Angebote" (Deals) — a Home section, not a category
This is different from the four above — it's a filtered view, not a new category.
- Audit whether `products`/listings already has a usable discount/compare-at-price
  field from the earlier commerce-model schema. If one exists and is safe to repurpose,
  use it. If not, add a minimal boolean (e.g. `is_discounted`) that a seller can toggle
  in the Sell flow when creating or editing a listing — don't build a full promotions/
  pricing-rules system for this.
- Add an "Angebote" section to the Home feed, alongside the existing "Neu eingetroffen"
  and "Beliebt in deiner Nähe" sections, showing listings flagged this way.

## 6. Definition of done
- `flutter analyze` clean.
- New categories appear in the category grid, subcategory browsing, filters, and the
  Sell flow's category picker with no Flutter code changes beyond what §5 needs.
- Real iOS screenshot of the category grid showing the new categories, and of the Home
  feed showing the new "Angebote" section.
- `docs/STATUS.md` updated noting the category expansion (this doesn't need its own
  full "Step" ledger entry — a short note is enough given the low risk).
