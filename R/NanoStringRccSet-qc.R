setGeneric("setQCFlags", signature = "object",
           function(object, ...) standardGeneric("setQCFlags"))
setMethod("setQCFlags", "NanoStringRccSet",
function(object,
         fovPercentLB = 0.75,
         bindDenRange = c(0.1, 1.8),
         posCtrlRsqLB = 0.95,
         negCtrlSDUB = 2,
         ...)
{
  stopifnot(isSinglePercent(fovPercentLB))
  stopifnot(is.numeric(bindDenRange) &&
              length(bindDenRange) == 2L &&
              !anyNA(bindDenRange) &&
              bindDenRange[1L] >= 0 &&
              bindDenRange[1L] < bindDenRange[2L])
  stopifnot(isSinglePercent(posCtrlRsqLB))

  # Extract Negative and Positive Controls
  negCtrl <- negativeControlSubset(object)
  posCtrl <- positiveControlSubset(object)
  posCtrl <- posCtrl[featureData(posCtrl)[["ControlConc"]] >= 0.5, ]
  controlConc <- featureData(posCtrl)[["ControlConc"]]


  # Update protocolData with QC Flags
  prData <- protocolData(object)

  prData[["FovFlag"]] <-
    prData[["FovCounted"]] / prData[["FovCount"]] < fovPercentLB

  prData[["BindFlag"]] <-
    prData[["BindingDensity"]] < bindDenRange[1L] |
    prData[["BindingDensity"]] > bindDenRange[2L]

  x <- log2(controlConc)
  prData[["LinFlag"]] <-
    esApply(posCtrl, 2L, function(y) cor(x, log2t(y, 0.5))^2 < posCtrlRsqLB)

  prData[["LoDFlag"]] <-
    apply(exprs(posCtrl[controlConc == 0.5, ]), 2L, max) <=
      esApply(negCtrl, 2L, function(x) mean(x) + negCtrlSDUB * sd(x))

  protocolData(object) <- prData


  # Add method call to preproc list
  preproc(object)["QCFlags"] <-
    list(match.call(call = sys.call(sys.parent(1L))))

  object
})


isSinglePercent <- function(x) {
  is.numeric(x) && length(x) == 1L && !anyNA(x) && x >= 0 && x <= 1
}