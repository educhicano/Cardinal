
#### Logging and flushing log to output files ####
## -----------------------------------------------

.log <- function(...) {
	msg <- paste(date(), paste0(..., collapse="\n  "))
	.Cardinal$log <- append(.Cardinal$log, msg)
}

.log.flush <- function(pkgname="Cardinal") {
	tryCatch({
		if ( length(.Cardinal$log) != 0 ) {
			filename <- paste(pkgname, "log", sep=".")
			filepath <- file.path(system.file(package=pkgname), filename)
			sink(filepath, append=TRUE)
			cat(paste(timestamp(quiet=TRUE)), "\n\n")
			for ( m in .Cardinal$log ) {
				cat(m, "\n\n")
			}
			.Cardinal$log <- list()
			sink()
		}
		TRUE
	}, error=function(e) FALSE)
}

#### User messages ####
## --------------------

.message <- function(..., progress=c("none", "start", "stop", "increment"), min=0, max=1) {
	.log(...)
	progress <- match.arg(progress)
	if ( progress == "none" ) {
		for ( f in .Cardinal$message ) {
			f(...)
		}
	} else if ( progress == "start" ) {
		.Cardinal$progress$min <- min
		.Cardinal$progress$max <- max
		for ( f in .Cardinal$progress$start ) {
			f(..., min=min, max=max)
		}
	} else if ( progress == "increment" ) {
		.Cardinal$progress$i <- .Cardinal$progress$i + 1
		for ( f in .Cardinal$progress$increment ) {
			f()
		}
	} else if ( progress == "stop" ) {
		for ( f in .Cardinal$progress$stop ) {
			f(...)
		}
	}
}

#### Console messages and progress bars ####
## -----------------------------------------

.console <- function(...) {
	if ( getOption("Cardinal.verbose") ) {
		message(...)
		flush.console()
	}
}

.progress.start <- function(..., min=0, max=1) {
	.message(...)
	if ( getOption("Cardinal.progress") ) {
		.Cardinal$progress$bar <- txtProgressBar(min=min, max=max, style=3)
	}
	.Cardinal$time$start <- proc.time()
}

.progress.increment <- function() {
	if ( getOption("Cardinal.progress") ) {
		setTxtProgressBar(.Cardinal$progress$bar, value=.Cardinal$progress$i)
	}
}

.progress.stop <- function(...) {
	.Cardinal$time$stop <- proc.time()
	if ( getOption("Cardinal.progress") ) {
		close(.Cardinal$progress$bar)
	}
	.message(...)
}

#### Generate entry for history log ####
## -------------------------------------

.history <- function(which=-2) {
	error <- paste("Error: in", deparse(match.call()))
	history <- tryCatch({
		call <- sys.call(which)
		def <- match.fun(as.character(call)[[1]])
		call <- match.call(def, call=call)
		history <- paste("Call:", deparse(call))
		if ( length(call) != 1 ) {
			args <- sapply(as.list(call)[-1], function(x) {
				tryCatch({
					class(eval(x, envir=sys.frame(which)))
				}, error=function(e) "unknown")
			})
			history <- append(history, paste(names(args), args, sep=" = "))
		}
		paste(history, collapse="\n")
	}, error=function(e) error)
	.log(history)
	history
}