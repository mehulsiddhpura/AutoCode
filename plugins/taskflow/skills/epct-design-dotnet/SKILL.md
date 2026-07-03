---
name: epct-design-dotnet
description: Theme-locked UI builder for .NET HTML-only projects (ASP.NET MVC Razor + jQuery + Bootstrap 3). Studies the existing house style first, then builds finished UI that looks native to the product, with static demo data by default. Runs autonomously with email notifications (no approval gate). Use for the .NET "HTML only" project type, or point it at one page task from an autocode pages/ pack.
---

# EPCT-Design — Codebase UI Builder (theme-locked, .NET HTML)

Build the UI/feature described here, end-to-end, in THIS codebase: `$ARGUMENTS`

**Theme-Study → Explore → Plan → Code → Test → Handoff**, grounded in this project's real conventions.

You are building front-end UI inside an **ASP.NET MVC (Razor) + jQuery + Bootstrap 3** project
(`PayTimeWebClient`). Goal: take one prompt (a task, optionally a Figma link and/or a reference page)
and deliver finished UI that **looks like it was always part of this product** — same buttons, cards,
modals, tables, spacing — with **static demo data by default**.

> ## THE ONE RULE
> **Never start writing a new page until you have studied the existing theme.** First look at the
> house style (buttons, cards, modals, toasts, tooltips, inputs, modal-cards, datatables-with-actions,
> body spacing). Then plan. *Only then* build. The Theme Study is the whole point of this command —
> it is mandatory every time, even when the task "looks simple."

Work **autonomously** — make sensible defaults from the rules below; only stop for a genuine **blocker**
or a choice that is genuinely the user's and cannot be inferred from the code, the Figma, or a
referenced page. Keep the user informed by **email** at the notification points below.

## Notifications — notify, don't gate (email the task owner via `scripts/notify-email.ps1`)

Send with `powershell -ExecutionPolicy Bypass -NoProfile -File scripts/notify-email.ps1 -Subject "<subject>" -Body "<body>"` (use `pwsh` if only PowerShell 7+ is installed). Email failures are non-fatal (log and continue).

- **Task start** — when you begin a page/task. Then proceed.
- **Plan done** — after Theme Study + Plan. Send the Theme-Study + Plan summary. **Informational only — do NOT wait for approval; continue straight to Code.**
- **Task done** — after the page's Self-QA passes.
- **All tasks done** — when the whole module/pack of pages is finished.
- **Blocker / intervention needed** — any phase, when progress is blocked or a decision only the owner can make is required. **STOP and email a proper summary:** what stopped it, why, and exactly what input is needed.

The only time you STOP is a real blocker (or an explicitly hard-to-reverse/destructive action).

---

## Defaults — apply these WITHOUT asking

- **Language:** reply in the user's language (Gujarati / Hinglish). Keep it short and concrete.
- **Static first:** build UI-only with realistic mock/static data. Do **not** wire a backend, API,
  or real persistence unless explicitly asked. State plainly that data/import wiring is left to the
  developer. If pagination/search/filter can't work on static data, keep them as UI (or make them
  work client-side if trivial) and say so.
- **CSS location:** all new CSS goes in `PayTimeWebClient/Newlayout/css/custom.css`.
  - **Reuse first.** Before adding a class, search custom.css for an existing one that fits.
  - Add new classes with a **feature prefix** (e.g. `dms-*`). Never duplicate an existing rule.
  - When iterating, **remove leftover unused / duplicate CSS** you created. Keep defined == used.
- **Targeted edits:** change only what the task needs. Don't refactor or restyle unrelated code,
  and don't break shared/global components used by other pages.
- **End every reply** with a one-line hard-refresh reminder: *"Ctrl+F5 કરીને ચેક કરો."*
- **Expect iteration.** Tweaks to spacing, position, color, highlight, responsiveness, scroll,
  copy, etc. will follow — make minimal, surgical edits.

---

## Inputs the user may give (any subset)

- **Task** (required) — what page/component/modal/flow to build or change.
- **Figma link(s)** with `node-id` — fetch and match the design (see Figma rules).
- **Reference page** ("X page ni jem", a `.cshtml` path) — read it and **replicate its pattern/classes**.
- **static / dynamic**, specific fields, data, counts, page size, etc.

---

# PHASE 0 — THEME STUDY (mandatory pre-build scan)

**Run this every time, before planning. Do not skip it because the task "looks simple."**
Open the real files and confirm the house style for **every** component the new page will use. The
**Theme Reference** below is the known baseline — treat it as a starting map, then **verify against
the live files** (values drift; trust the file over this doc).

Always open:
1. `PayTimeWebClient/Newlayout/css/custom.css` — the master theme (search the sections you need).
2. A recent, clean reference view that matches your task. Best current examples:
   `Views/DMS/CompanyFiles.cshtml`, `Views/DMS/EmployeeFiles.cshtml`,
   `Views/DMS/ManageCategories.cshtml`, `Views/DMS/MyFiles.cshtml`,
   side-filter pattern — `Views/TP/PreviousRewards.cshtml`.
3. `Views/Shared/_Layout.cshtml` — what CSS/JS is already loaded (don't re-import anything).
4. Any **reference page** or **Figma node** the user named.

**Theme-Study checklist — tick each component the page touches:**

- [ ] **Body / page spacing** — `.page-bar` + breadcrumb, `.portlet` > `.portlet-body`, container `.row`/`col-*`, tab content padding.
- [ ] **Buttons** — primary `.save_btn`, secondary `.cancel_btn`, destructive `.clear_btn`, toolbar `.icon_transparent_btn` / `.icon_btn`, row-action `.blue_btnnew`. Confirm which goes where.
- [ ] **Inputs** — `.form-control`, `.select2`, `.mt-multiselect`, radio/checkbox, required `<span class="required">*</span>`.
- [ ] **Cards** — `.portlet`, `.modal-card`, `.repo_bg`. Confirm padding/radius/shadow.
- [ ] **Modal** — header/body/`.modal-card`/footer skeleton + footer button pairing + trigger.
- [ ] **DataTable with actions** — markup + `dom: _domCommon`, `language: _languageCommon`, action column non-orderable, header-move snippet, action-cell buttons.
- [ ] **Toast** — `toastr.success/info/error` for outcomes.
- [ ] **Tooltips** — `.tooltips` + `data-original-title`, `$('.tooltips').tooltip()` (re-init after re-render).
- [ ] **Pills / badges** — `.dms-pill.dms-pill-{type|tag|edu|emp|bank|ok|off}` or existing badge.
- [ ] **SweetAlert** — the project's `Swal.fire` confirm pattern (icon `<img>` in title + `swal_*` skin class).
- [ ] **Empty state** — `.datanotfound` block (`emptyscreen_1.png`).
- [ ] **Filter side panel** (if needed) — `.filter_portlet_wrapper.full-width` + `#Filter_search` toggle JS.
- [ ] **Tabs** (if needed) — `.nav-tabs-custom` + `.tab_content_box`; lazy-init DataTables on `shown.bs.tab`.
- [ ] **Page loader** — `#ajax_loader.modal_bg.loading` after the page bar (if async actions exist).
- [ ] **Status text** — `.green_font` / `.orange_font` / `.red_font` for approved/pending/rejected.

---

# COMPONENT LIBRARY — verified house style (copy-paste ready)

> **Source of truth:** extracted from the live project at
> `D:\All Projects\MINOP\old_ui_minop_frontend\PayTimeWebClient`
> (`Newlayout/css/custom.css` ~11k lines, `Newlayout/js/dataTableSorting.js`,
> `Views/Shared/_Layout.cshtml`, `Views/DMS/*.cshtml`, `Views/TP/PreviousRewards.cshtml`).
> Every snippet below uses **real classes that exist in the project**. Reuse them; don't invent new ones.
>
> ⚠️ **Hex vs vars:** only **two** CSS custom properties exist — `--navyblue_color: #295097`
> and `--navyblue_hover: #1d4183`. Every other color is a **literal hex** inside `custom.css`.
> So: use `var(--navyblue_color)` for navy, otherwise **reuse the documented class** rather than
> introducing a new hex. Never add a hardcoded navy hex.

## 0. Design tokens (verified)

- **Brand / primary:** `var(--navyblue_color)` = `#295097`; hover `var(--navyblue_hover)` = `#1d4183`.
- **Destructive red:** `#d75353` (clear btn) / `#D43F3A` (swal/hover). **Success green:** `#2e7d32`. **Muted grey:** `#9e9e9e`.
- **Surfaces:** white `#fff`; `.modal-card` bg `#f7f8f9`; filter footer `#F7F8FA`.
- **Borders:** inputs `#c2cad8`, light dividers `#e3e3e3` / `#d9d9d9`.
- **Text:** primary `#333`, secondary `#666`, muted `#999` / `#6B6C7E`.
- **Font:** `'Roboto', sans-serif`; body **13px** (letter-spacing .2px); `.form-control` **12px**; select2 **12px**; pills **11px**; `.datanotfound_title`/page title **16px**; tooltip **12px**.
- **Radius:** buttons/controls/inputs/`.form-control` **3px**; cards/`.portlet`/`.modal-card` **6px**; tooltip **4px**; pills **999px**.
- **Control height:** **30px** standard (clear/search/icon/icon_transparent/trans_btnnew); **32px** save/cancel; row-action icon btns **26px**.
- **Icons:** **FontAwesome 6** — `fa-regular` (default), `fa-solid`, `fa-light`. Already loaded; never re-add.

## 1. Page scaffold — page-bar + breadcrumb + toolbar + loader

```html
<!-- Page Bar : Begin -->
<div class="page-bar">
    <ul class="page-breadcrumb">
        <li><a href="/Admin/AdminDashboard"><i class="fa-regular fa-house"></i></a></li>
        <li><span><i class="fa-light fa-angle-right"></i> Company Files</span></li>
    </ul>
    <div class="page-toolbar">
        <!-- Filter toggle (see §13) -->
        <a href="javascript:;" id="Filter_search" class="btn icon_transparent_btn tooltips margin-left-5" data-placement="left" data-original-title="Filter"><i class="fa-light fa-filter"></i></a>
        <!-- Primary toolbar action (Upload / + Add) -->
        <a href="javascript:;" class="btn icon_transparent_btn tooltips margin-left-5 dmsUploadBtn" data-placement="left" data-original-title="Upload Document"><i class="fa-regular fa-arrow-up-from-bracket"></i></a>
    </div>
</div>

<!-- Standard ajax loader: place right after the page bar -->
<div id="ajax_loader" class="modal_bg loading" aria-hidden="true">
    <img src="~/LandingAssets/images/loading.gif" style="cursor:auto; width:80px;" />
</div>
```

## 2. Portlet card (the standard content container)

```html
<div class="row">
    <div class="col-lg-12 col-md-12 col-sm-12 col-xs-12">
        <div class="portlet">           <!-- white, padding 12px, radius 6px, subtle shadow -->
            <div class="portlet-body">
                <!-- table / form / content -->
            </div>
        </div>
    </div>
</div>
```

## 3. Buttons (verified — `.btn` + role class)

| Role | Class | Look | Height |
|------|-------|------|--------|
| Primary / save | `.btn.save_btn` | navy bg, white text | 32px |
| Add | `.btn.add_btn` | navy bg, white | 30px |
| Search (table/filter) | `.btn.search_btn` | navy bg, white | 30px |
| Secondary / close | `.btn.cancel_btn` | grey `#9e9e9e` bg, white | 32px |
| Destructive / clear | `.btn.clear_btn` | white bg, red `#d75353` text+border, hover fills red | 30px |
| Toolbar (page-bar) | `.btn.icon_transparent_btn` | grey `#e7e8eb` bg, navy icon | 30px |
| Toolbar outline / filter apply | `.btn.icon_btn` | white bg, navy text+border, hover fills navy | 30px |
| Neutral | `.btn.trans_btnnew` | white bg, `#444` text, `#d9d9d9` border | 30px |
| Download / Update / Process | `.download_btn` / `.update_btn` / `.process_btn` | navy bg, white | 30px |
| Row action (table) | `.btn.blue_btnnew` | **transparent, grey `#666` icon**, hover light-grey `#f8f8f8` card | 26px |
| Upload icon (in cell) | `.blueupload_btn` (navy) / `.redupload_btn` (red) | white bg + colored icon | 26px |

> ⚠️ `.blue_btnnew` / `.green_btnnew` / `.red_btnnew` / `.seagreen_btnnew` are **all identical** transparent grey-icon buttons — the color name is legacy, not the actual color. Use any for row actions.
> Primary buttons usually carry a leading icon: `<button class="btn save_btn"><i class="fa-light fa-floppy-disk"></i> Save</button>`.

## 4. Modal (skeleton + trigger + select2-in-modal)

Trigger wires `data-toggle`/`data-target` on click via a hook class:
```html
<a href="javascript:;" class="btn icon_transparent_btn tooltips dmsUploadBtn" data-placement="left" data-original-title="Upload Document"><i class="fa-regular fa-arrow-up-from-bracket"></i></a>
```
```js
$(".dmsUploadBtn").on('click', function () {
    $(".dmsUploadBtn").attr("data-toggle", "modal").attr("data-target", "#uploadModal");
});
```

Skeleton (width variants: `.w-500`, `.w-900`, `.w-1080` — no others exist):
```html
<div id="uploadModal" class="modal fade" role="dialog" data-keyboard="false" data-backdrop="static">
    <div class="modal-dialog w-500">
        <div class="modal-content">
            <div class="modal-header">
                <button type="button" class="close" data-dismiss="modal">&times;</button>
                <h4 class="modal-title">Upload Document</h4>
            </div>
            <div class="modal-body">
                <div class="modal-card">          <!-- detail/grey-card style; optional for plain forms -->
                    <!-- form-groups here -->
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn clear_btn" data-dismiss="modal">Cancel</button>
                <button type="button" class="btn save_btn"><i class="fa-regular fa-arrow-up-from-bracket"></i> Upload</button>
            </div>
        </div>
    </div>
</div>
```
select2 inside a modal needs `dropdownParent` and must init on `shown.bs.modal`:
```js
$("#uploadModal").on('shown.bs.modal', function () {
    var $m = $(this);
    try { $m.find('.select2').select2({ dropdownParent: $m, width: '100%' }); } catch (e) {}
});
```

## 5. Inputs & form controls

```html
<!-- Required text input -->
<div class="form-group">
    <label class="control-label">Category Name <span class="required" aria-required="true"> * </span></label>
    <input type="text" class="form-control input-sm" placeholder="e.g. Personal Documents" />
</div>

<!-- Single select (select2) -->
<div class="form-group">
    <label class="control-label">Company <span class="required" aria-required="true"> * </span></label>
    <select class="form-control input-sm select2">
        <option value="">Please Select</option>
        <option value="1">Company 1</option>
    </select>
</div>

<!-- Multi-select = bootstrap-multiselect (NOT select2) -->
<select id="EmployeeID" class="mt-multiselect btn blue btn-outline" multiple="multiple" data-width="100%">
    <option value="1">Vitesh Patel</option>
</select>

<!-- Textarea -->
<div class="form-group">
    <label>Add Comment</label>
    <textarea class="form-control" rows="3" placeholder="Write your message..."></textarea>
</div>

<!-- Radio / checkbox (Metronic mt-* controls) -->
<label class="mt-radio mt-radio-outline">Individual Employees<input type="radio" name="shareScope" value="individual" checked /><span></span></label>
<label class="check mt-checkbox mt-checkbox-outline"><input type="checkbox" checked> Active<span></span></label>
```
```js
// page-level select2
$(".select2").select2({ width: '100%' });
// bootstrap-multiselect
$("#EmployeeID").multiselect({
    includeSelectAllOption: true, enableFiltering: true, enableCaseInsensitiveFiltering: true,
    maxHeight: 300, buttonWidth: '100%', nonSelectedText: 'Select Employee'
});
```

## 6. DataTable with action column

```html
<div class="table-responsive" id="tableResponsive">
    <table id="tblFiles" class="new_datatbl table table-striped table-bordered table-hover order-column">
        <thead>
            <tr>
                <th style="min-width:180px;">Name</th>
                <th>Modified</th>
                <th>Tags</th>
                <th style="min-width:170px;">Action</th>
            </tr>
        </thead>
        <tbody>
            <tr>
                <td>Employee Handbook.pdf</td>
                <td>16 Jun 2026</td>
                <td><span class="dms-pill dms-pill-tag">HR</span></td>
                <td>   <!-- ACTION CELL -->
                    <a href="javascript:;" class="btn blue_btnnew tooltips" data-placement="left" data-original-title="Download"><i class="fa-regular fa-download"></i></a>
                    <a href="javascript:;" class="btn blue_btnnew tooltips dmsEditBtn" data-placement="left" data-original-title="Edit"><i class="fa-regular fa-pen-to-square"></i></a>
                    <a href="javascript:;" class="btn blue_btnnew tooltips dmsDeleteBtn" data-placement="left" data-original-title="Delete"><i class="fa-regular fa-trash-can"></i></a>
                </td>
            </tr>
        </tbody>
    </table>
</div>
```
Action-icon vocabulary: View `fa-eye`, Download `fa-download`, Edit `fa-pen-to-square`, Delete `fa-trash-can`, Share `fa-share-nodes`, Inactivate `fa-xmark`, Activate `fa-check`.

Init (use globals `_domCommon` + `_languageCommon` from `dataTableSorting.js` — already loaded):
```js
$("#tblFiles").DataTable({
    dom: _domCommon, language: _languageCommon, ordering: true,
    columnDefs: [{ orderable: false, targets: [3] }]   // Action col not sortable
});
setTimeout(function () {
    $("#tblFiles_wrapper #dataTables_tbl_header").insertBefore($("#tableResponsive"));
    $('.tooltips').tooltip();
}, 100);
```
**Inside a tab**, lazy-init on `shown.bs.tab` and guard double-init:
```js
$('a[data-toggle="tab"][href="#dmsFilesPane"]').on('shown.bs.tab', function () {
    if (!$.fn.DataTable.isDataTable('#tblEmpFiles')) { /* DataTable({...}) + setTimeout header-move */ }
});
```
**Per-column footer search** (optional — use `_domColumn`/`_languageColumn` instead):
```js
$("#tbl thead").on("keyup", "input", function () {
    table.column($(this).parent().index()).search(this.value).draw();
});
```
Excel export is automatic via the shared `#export-button` infra — register the table id in the `dict` map in `dataTableSorting.js`.

## 7. Pills / badges (status & tags)

```html
<span class="dms-pill dms-pill-tag">HR</span>            <!-- blue tag  #eaf2ff / #1f4e9d -->
<span class="dms-pill dms-pill-edu">Education</span>     <!-- blue      #eaf2ff / #1f4e9d -->
<span class="dms-pill dms-pill-type">Personal</span>     <!-- green     #eaf6ed / #2e7d32 -->
<span class="dms-pill dms-pill-emp">Employment</span>    <!-- purple    #f0eaff / #6a3fb5 -->
<span class="dms-pill dms-pill-bank">Banking</span>      <!-- amber     #fff4e0 / #b5790f -->
<span class="dms-pill dms-pill-ok">Active</span>         <!-- green     #eaf6ed / #2e7d32 -->
<span class="dms-pill dms-pill-off">Inactive</span>      <!-- red       #fff1f0 / #d9363e -->
```
These 7 are the only `.dms-pill-*` variants that exist. For plain status **text** in a cell, use `.green_font` (Approved), `.orange_font` (Pending), `.red_font` (Rejected).

## 8. Tabs

```html
<ul class="nav nav-tabs nav-tabs-custom" role="tablist">
    <li class="nav-item active"><a class="nav-link" data-toggle="tab" href="#paneA" role="tab"><i class="fa-light fa-users"></i><span>Employees</span></a></li>
    <li class="nav-item"><a class="nav-link" data-toggle="tab" href="#paneB" role="tab"><i class="fa-light fa-folder-open"></i><span>Files</span></a></li>
</ul>
<div class="tab-content text-muted tab_content_box">
    <div class="tab-pane active" id="paneA" role="tabpanel"><!-- ... --></div>
    <div class="tab-pane" id="paneB" role="tabpanel"><!-- DataTable lazy-inits on shown.bs.tab --></div>
</div>
```

## 9. Tooltips

Any element with `.tooltips` + `data-placement` + `data-original-title` — activate after render with `$('.tooltips').tooltip();` (re-call after injecting dynamic rows). Skin (white bg, navy border, radius 4px) is automatic via `.tooltip-inner`.

## 10. Toastr (outcome feedback)

```js
if (window.toastr) { toastr.success("Files imported successfully."); }
// toastr.error(...) / toastr.info(...) / toastr.warning(...)
```

## 11. SweetAlert (Swal — SweetAlert2 v9, project pattern)

Icon is an `<img>` inside the `title` (the project does **not** use Swal's built-in `icon:`). Add the state skin class after render.
```js
Swal.fire({
  title: "<img class='margin-right-5' src='/assets/images/icons/swal_icon/icon_error.svg' alt=''>Delete document",
  html: "<div class='swal_subtitle'><b>Are you sure you want to delete this?</b></div>",
  showCloseButton:true, showCancelButton:true, confirmButtonText:'Yes', cancelButtonText:'No',
  allowOutsideClick:false, allowEscapeKey:false,
  customClass:{ confirmButton:'swal-confirm-button-class', cancelButton:'swal-cancel-button-class' }
}).then(function (result) {
  if (result.isConfirmed) { /* do it, then toastr.success(...) */ }
});
setTimeout(()=>$('img[src*="icon_error.svg"]').closest('.swal2-popup').addClass('swal_error'),50);
```
- **Icon set** (`/assets/images/icons/swal_icon/`): `icon_info.svg`, `icon_success.svg`, `icon_error.svg`, `icon_warning.svg`.
- **Skin class** matches the icon: `swal_error` / `swal_info` / `swal_success` / `swal_warning` / `swal_question` (colored top border).
- To stack **above an open modal**, add `customClass.container: 'dms-swal-top'` (`z-index:100000`).
- Forms needing input: add `preConfirm: () => {...}` + `Swal.showValidationMessage(...)`.

## 12. Empty state

```html
<div id="NotificationGrid-empty" style="display:none;">
    <div class="datanotfound">
        <img src="~/assets/images/emptyscreen_1.png" height="148" width="280" alt="Nodata Found Icon">
        <p class="datanotfound_title">No data found</p>
        <p>No company files yet.</p>
    </div>
</div>
```

## 13. Filter side panel (reference: `Views/TP/PreviousRewards.cshtml`)

Wrapper **starts collapsed** via `.full-width`; the toolbar `#Filter_search` (§1) toggles it. Tabs, if any, stay **outside** the wrapper.
```html
<div class="filter_portlet_wrapper full-width">   <!-- full-width = collapsed -->
    <!-- LEFT: content -->
    <div class="filter_portlet_tbl">
        <div class="portlet"><div class="portlet-body">
            <!-- table-responsive / datatable + .datanotfound -->
        </div></div>
    </div>
    <!-- RIGHT: slide-in filter panel -->
    <div class="portlet filter_boxModal">
        <div class="filterbox_header">
            <div class="d-flex align-items-center justify-content-between">
                <h4 class="filter-title">Filters</h4>
                <button type="button" class="filterclose_btn"><i class="fa-light fa-xmark"></i></button>
            </div>
        </div>
        <div class="filterbox_body">
            <div class="col-lg-12"><div class="form-group">
                <label class="control-label">Company</label>
                <select class="form-control input-sm select2"><!-- ... --></select>
            </div></div>
            <!-- multiselect filters use .mt-multiselect (§5) -->
        </div>
        <div class="filterbox_footer">
            <div class="text-right">
                <button type="button" class="clear_btn tooltips" data-placement="top" data-original-title="Clear Filters"><i class="fa-regular fa-eraser"></i></button>
                <button type="button" class="icon_btn margin-left-5 tooltips" data-placement="top" data-original-title="Search Filters"><i class="fa-solid fa-magnifying-glass"></i></button>
            </div>
        </div>
    </div>
</div>
```
```js
$("#Filter_search").click(function () { $(".filter_portlet_wrapper").toggleClass("full-width"); });
$(".filterclose_btn").click(function () { $(".filter_portlet_wrapper").addClass("full-width"); });
```
Footer is **icon-only** (eraser = clear, magnifier = apply) — no text buttons.

## 14. Spacing / utility classes (verified naming)

The project uses **verbose hyphenated** utilities in steps of 5 (`0`–`50`) — **NOT** Tailwind-style `mt-10`/`mr-5`:
- `.padding-{N}`, `.padding-top-{N}`, `.padding-bottom-{N}`, `.padding-left-{N}`, `.padding-right-{N}`
- `.margin-left-{N}`, `.margin-right-{N}` (e.g. `margin-left-5`, `margin-right-10`)

## 15. Assets already loaded in `_Layout.cshtml` — NEVER re-import

jQuery, **Bootstrap 3** (CSS+JS), **select2** + bootstrap-multiselect, **toastr** (CSS+JS),
**DataTables** (+ColReorder), **FontAwesome v6**, jQuery UI, **SweetAlert2 (Swal)**, animate.css,
icomoon, ExcelJS/jsPDF export libs, and `custom.css` / `datatable_custom.css` / `responsive.css` / `menu.css`.
DataTable globals `_domCommon` / `_languageCommon` (+ `_domColumn` / `_languageColumn`) come from
`Newlayout/js/dataTableSorting.js`. Pages additionally link `payrollstructure.css` (and `mysubscription.css` for tabbed pages).

---

## Figma rules (when a figma.com link with node-id is given)

1. Use the Figma MCP: `get_design_context` (code + screenshot) and/or `get_screenshot` per node.
   Extract `fileKey` and `node-id` from the URL (`…/design/:fileKey/…?node-id=1-2`).
2. **Match the visual design** (layout, spacing, colors, copy, states) — but **translate to THIS
   project's stack and classes**. Ignore the returned React/Tailwind; never add Tailwind or React.
3. Use the project's components/classes (Theme Reference above), not Figma's class names. Add real
   `<img>`/icons where the design shows them. Build every state shown (default / error / success / empty).
4. If the URL has no `node-id`, ask for a node-specific link.

When the user points to **another existing page** instead of Figma: read that file and replicate its
markup pattern, classes, and JS wiring.

---

## Process (one pass, theme-locked, autonomous)

0. **Task start** — email "Task start" (page name + what it covers), then proceed.
1. **Theme Study** — run Phase 0 above. Open the files, tick the checklist for every component the
   page uses. Don't write page code yet.
2. **Explore** — read the target view, the relevant `custom.css` section, any referenced page, and
   (if given) the Figma node. Note reusable classes/patterns + the states required.
3. **Plan** — decide structure quickly. Surface a question *only* for a real, user-owned decision
   (use the question tool with concrete options). Otherwise proceed.
4. **Email "Plan done"** — post the short Theme-Study + Plan summary (template below) and email it.
   **This is informational — do NOT wait for approval; continue straight to Code.**
5. **Code** — implement the `.cshtml` (HTML + inline `<script>`) and add/extend CSS in `custom.css`
   using the conventions above. Include all states, responsive behavior, and static data.
6. **Test** — run the Self-QA checklist below; fix what fails.
7. **Handoff** — concise summary (in the user's language): what was added/changed (file + section),
   any assumptions (e.g. "static, no backend"), what's left for the developer, and the Ctrl+F5 reminder.
   Then **email "Task done"** (what shipped + any deferred items). When the whole pack of pages is
   finished, email **"All tasks done"**.

### The Plan-done summary (email this, then continue — no gate)

After Theme Study + Plan, post this short block **in the user's language** and email it as "Plan done",
then **keep building** (do not wait):

```
🎨 Theme Study
• Buttons:  .save_btn (primary) / .clear_btn (delete) / .blue_btnnew (row actions)
• Card:     .portlet > .portlet-body   |  Modal: .modal-card style, footer = cancel + save
• Table:    _domCommon DataTable, action col non-orderable
• Inputs:   .form-control + .select2   |  Pills: .dms-pill-*   |  Tooltips + toastr wired
• Spacing/colors: house tokens (navy #295097, 13px Roboto, radius 3/6px)

🧩 Plan
• <file(s) to create/edit> — <sections> — <states> — static demo data
```

- If the user's prompt explicitly says "wait" / "let me review the plan first", then hold before Code —
  otherwise proceed automatically. Small follow-up tweaks afterwards never need approval.
- Still stop and get sign-off independently before any **hard-to-reverse / destructive** action
  (send a "Blocker / intervention needed" email with the details).

---

## Design Principles (MUST FOLLOW)

### Usability
- Every screen has ONE clear primary action.
- Provide a back / cancel / undo path — never trap the user.
- Design all states: default, loading, empty, error, success.
- Match labels to the user's vocabulary, not internal jargon.
- Confirm or make reversible any destructive action.
- Give feedback within ~100ms for every interaction.

### Accessibility
- Text contrast ≥ 4.5:1 (≥ 3:1 for large text); UI/icons ≥ 3:1.
- Never rely on color alone to convey meaning.
- Every control has a visible focus state and an accessible label.
- Touch targets ≥ 44×44pt; respect platform minimum text sizes.
- Reading / focus order is logical; support reduced motion.

### Consistency & Design System
- Use existing components and variants — never detach without reason.
- Use tokens/shared values for color, type, spacing, radius, elevation.
- Follow the system spacing/type scale — no arbitrary one-off values.
- Keep patterns consistent across all screens in the flow.

### Content & Microcopy
- Write clear, specific labels and button text (verbs for actions).
- Error messages say what happened AND how to fix it.
- Keep voice & tone consistent; provide microcopy for empty states and edge cases.

### Interaction & Motion
- Define all interactive states: hover, pressed, focus, disabled, selected.
- Use motion to clarify cause/effect — not decoration.
- Show progress/feedback for async or long actions; keep transitions fast and purposeful.

### Responsive & Platform
- Define behavior at each breakpoint / size class; content reflows without clipping or overlap.
- Respect platform conventions; handle safe areas, keyboards, and system bars.

### Handoff Completeness
- Components reference the design system (not detached); all states present and documented.
- Specs/constraints provided; assets export-ready (format, density, naming).

---

## Self-QA checklist (run before Handoff — a check, not a gate)

| # | Category | Verify |
|---|----------|--------|
| 0 | Theme match | Buttons/cards/modal/table/inputs/pills/spacing match the Theme Reference — looks native |
| 1 | Happy path | Core flow completes with one obvious primary action per step |
| 2 | Edge & error paths | Empty, loading, error, success + recovery states designed |
| 3 | Accessibility | Contrast, no color-only meaning, focus + labels, touch targets |
| 4 | Edge cases | Long text, missing/zero/many items, smallest & largest widths |
| 5 | Flow trace | Every branch, back, cancel, dead-end accounted for |
| 6 | Components | System variants/classes reused; nothing detached without reason |
| 7 | Principles | All Design Principles re-verified |
| 8 | Responsive | Works at each target breakpoint — no clipping/overlap |
| 9 | Traceability | Every requested screen/state built; no scope drift |
| 10 | No regressions | Shared/global components not broken; trigger/handler targets exist |
| 11 | CSS hygiene | No duplicate/unused classes added; defined == used; new classes prefixed |
| 12 | No re-imports | Didn't re-add jQuery/Bootstrap/DataTables/select2/toastr/FA — already in `_Layout` |
| 13 | DoD | No lorem/placeholder left; interactions wired; matches Figma/reference |

If anything fails — fix it, re-check, then report. If a check fails and you cannot resolve it
yourself, treat it as a **blocker** and email the details.

---

## Optional (only if the user asks)
- **Artifact:** save a phase/decision log or summary to `design/epct/{TASK_ID}.md` (or the path the user names) and link it.
- **Design QA report:** in addition to the Self-QA, present a final Design QA Report (from the table above) before Handoff — use this only when the user explicitly wants a closing checkpoint too.
