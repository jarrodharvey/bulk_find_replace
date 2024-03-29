rm(list = ls())
cat("\14")

spreadsheet_to_update <- readxl::read_excel(
  "data/spreadsheet_to_update.xlsx"
)

replacements <- readxl::read_excel(
  "data/replacements.xlsx"
) |>
  purrr::modify_at(
    "Original",
    # Escape the characters that have special meaning in regex
    ~ stringr::str_replace_all(
      .x,
      "([\\^\\$\\.\\?\\*\\|\\+\\(\\)\\[\\{\\]])",
      "\\\\\\1"
    ) |> (\(.) {
      # Make the regex case insensive and match the entire content of the cell
      glue::glue("(?i)^{.}$")
    })()
  )

new_sheet <- purrr::reduce2(
  replacements$Original,
  replacements$Replacement,
  \(sheet, original, replacement) {
    sheet |>
      dplyr::mutate(
        across(everything(), ~ stringr::str_replace(.x, original, replacement))
      )
  },
  .init = spreadsheet_to_update
) |>
  as.data.frame()

xlsx::write.xlsx2(
  x = new_sheet,
  file = "output/cleaned_sheet.xlsx",
  row.names = FALSE
)