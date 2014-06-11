
#### Signal smoothing methods ####
## -------------------------------

setMethod("smoothSignal", "MSImageSet",
	function(object, method = c("gaussian", "sgolay", "ma"),
		...,
		pixel=pixels(object),
		plot=FALSE)
	{
		if ( centroided(object) )
			.stop("Data already centroided. Smoothing will not be performed.")
		fun <- smoothSignal.method(method)
		data <- pixelApply(object, function(s, ...) {
			sout <- fun(s, ...)
			if ( plot ) {
				wrap(plot(object, pixel=.Index, col="gray", ...),
					..., signature=fun)
				wrap(lines(mz(object), sout, lwd=0.5, ...),
					..., signature=fun)
			}
			sout
		}, .pixel=pixel, ..., .use.names=FALSE, .simplify=TRUE)
		object@imageData <- SImageData(data=data,
			coord=coord(object)[pixel,],
			storageMode=storageMode(object@imageData),
			dimnames=list(featureNames(object), pixelNames(object)[pixel]))
		object@pixelData <- object@pixelData[pixel,]
		smoothing(processingData(object)) <- match.method(method)
		prochistory(processingData(object)) <- .history()
		object
	})

smoothSignal.method <- function(method) {
	if ( is.character(method) ) {
		method <- switch(method[[1]],
			gaussian = smoothSignal.gaussian,
			sgolay = smoothSignal.sgolay,
			ma = smoothSignal.ma,
			match.fun(method))
	}
	match.fun(method)
}

smoothSignal.ma <- function(x, coef=rep(1, window + 1 - window %% 2), window=5, ...) {
	coef <- coef / sum(coef)
	window <- length(coef)
	halfWindow <- floor(window / 2)
	xpad <- c(rep(x[[1]], halfWindow), x, rep(x[[length(x)]], halfWindow))
	filter(xpad, filter=coef)[(halfWindow + 1):(length(xpad) - halfWindow)]
}

smoothSignal.gaussian <- function(x, sd=window/4, window=5, ...) {
	halfWindow <- floor(window / 2)
	coef <- dnorm((-halfWindow):halfWindow, sd=sd)
	smoothSignal.ma(x, coef=coef, ...)
}

smoothSignal.kaiser <- function(x, beta=1, window=5, ...) {
	coef <- kaiser(n=window + 1 - window %% 2, beta=beta)
	smoothSignal.ma(x, coef=coef, ...)
}

smoothSignal.sgolay <- function(x, order=3, window=order + 3 - order %% 2, ...) {
	window <- window + 1 - window %% 2
	sgolayfilt(x, p=order, n=window)
}