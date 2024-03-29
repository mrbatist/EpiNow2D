#' Updates Forecast Horizon Based on Input Data and Target
#'
#' @description `r lifecycle::badge("stable")`
#' Makes sure that a forecast is returned for the user specified time period
#' beyond the target date.
#' @inheritParams setup_target_folder
#' @inheritParams estimate_infections
#' @return Numeric forecast horizon adjusted for the users intention
#' @author Sam Abbott
#' @export
update_horizon <- function(horizon, target_date, reported_cases) {
  if (horizon != 0) {
    horizon <- horizon + as.numeric(
      as.Date(target_date) - max(reported_cases$date)
    )
  }
  return(horizon)
}

#' Save Observed Data
#'
#' @description `r lifecycle::badge("stable")`
#' Saves observed data to a target location if given.
#'
#' @inheritParams setup_target_folder
#' @inheritParams epinow
#' @return No return value, called for side effects
#' @author Sam Abbott
#' @export
save_input <- function(reported_cases, target_folder) {
  if (!is.null(target_folder)) {
    latest_date <- reported_cases[confirm > 0][date == max(date)]$date

    saveRDS(latest_date, paste0(target_folder, "/latest_date.rds"))
    saveRDS(reported_cases, paste0(target_folder, "/reported_cases.rds"))
  }
  return(invisible(NULL))
}



#' Save Estimated Infections
#'
#' @description `r lifecycle::badge("stable")`
#' Saves output from `estimate_infections` to a target directory.
#' @param estimates List of data frames as output by `estimate_infections`
#'
#' @param samples Logical, defaults to TRUE. Should samples be saved
#'
#' @param return_fit Logical, defaults to TRUE. Should the fit stan object
#' be returned.
#'
#' @seealso estimate_infections
#' @author Sam Abbott
#' @inheritParams setup_target_folder
#' @inheritParams  estimate_infections
#' @return No return value, called for side effects
#' @export
save_estimate_infections <- function(estimates, target_folder = NULL,
                                     samples = TRUE, return_fit = TRUE) {
  if (!is.null(target_folder)) {
    if (samples) {
      saveRDS(
        estimates$samples, file.path(target_folder, "estimate_samples.rds")
      )
    }
    saveRDS(
      estimates$summarised,
      file.path(target_folder, "summarised_estimates.rds")
    )
    if (return_fit) {
      saveRDS(estimates$fit, file.path(target_folder, "model_fit.rds"))
      saveRDS(estimates$args, file.path(target_folder, "model_args.rds"))
    }
  }
  return(invisible(NULL))
}

#' Estimate Cases by Report Date
#'
#' @description `r lifecycle::badge("questioning")`
#' Either extracts or converts reported cases from an input data table. For
#' output from `estimate_infections` this is a simple filtering step.
#'
#' @inheritParams setup_target_folder
#' @inheritParams save_estimate_infections
#' @inheritParams estimate_infections
#'
#' @return A list of samples and summarised estimates of estimated cases by
#' date of report.
#' @author Sam Abbott
#' @export
#' @importFrom data.table := rbindlist
estimates_by_report_date <- function(estimates, CrIs = c(0.01, 0.025, 0.05, 0.1, 0.15, 0.2, 0.25, 0.3,0.35,0.4,0.45,0.5,0.55,0.6,0.65,0.7,0.75,0.8,0.85,0.9,0.95,0.975,0.99),
                                     target_folder = NULL, samples = TRUE) {
  estimated_reported_cases <- list()
  if (samples) {
    estimated_reported_cases$samples <- estimates$samples[
      variable == "reported_cases"][,
      .(date, sample, cases = value, type = "gp_rt")
    ]
  }
  estimated_reported_cases$summarised <- estimates$summarised[
    variable == "reported_cases"][,
    type := "gp_rt"
  ][, variable := NULL][, strat := NULL]

  if (!is.null(target_folder)) {
    if (samples) {
      saveRDS(
        estimated_reported_cases$samples,
        file.path(target_folder, "estimated_reported_cases_samples.rds")
      )
    }
    saveRDS(
      estimated_reported_cases$summarised,
      file.path(target_folder, "summarised_estimated_reported_cases.rds")
    )
  }
  return(estimated_reported_cases)
}



#' Copy Results From Dated Folder to Latest
#'
#' @description `r lifecycle::badge("questioning")`
#' Copies output from the dated folder to a latest folder. May be undergo
#' changes in later releases.
#'
#' @param latest_folder Character string containing the path to the latest
#' target folder. As produced by `setup_target_folder`.
#'
#' @inheritParams setup_target_folder
#'
#' @return No return value, called for side effects
#' @author Sam Abbott
#' @export
copy_results_to_latest <- function(target_folder = NULL, latest_folder = NULL) {
  if (!is.null(target_folder)) {
    ## Save all results to a latest folder as well
    suppressWarnings(
      if (dir.exists(latest_folder)) {
        unlink(latest_folder)
      }
    )

    suppressWarnings(
      dir.create(latest_folder)
    )

    suppressWarnings(
      file.copy(file.path(target_folder, "."),
        latest_folder,
        recursive = TRUE
      )
    )
  }
  return(invisible(NULL))
}


#' Construct Output
#'
#' @description `r lifecycle::badge("stable")`
#' Combines the output produced internally by `epinow` into a single list.
#'
#' @param estimated_reported_cases A list of dataframes as produced by
#' `estimates_by_report_date`.
#'
#' @param plots A list of plots as produced by `report_plots`.
#'
#' @param summary A list of summary output as produced by `report_summary`.
#'
#' @inheritParams save_estimate_infections
#'
#' @return A list of output as returned by `epinow`
#' @author Sam Abbott
#' @export
construct_output <- function(estimates,
                             estimated_reported_cases,
                             plots = NULL,
                             summary = NULL,
                             samples = TRUE) {
  out <- list()
  out$estimates <- estimates
  if (!samples) {
    out$estimates$samples <- NULL
  }
  out$estimated_reported_cases <- estimated_reported_cases
  out$summary <- summary

  if (!is.null(plots)) {
    out$plots <- plots
  }
  return(out)
}
