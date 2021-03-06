
## Convert names of data types to their size in number of bytes
Csizeof <- function(type) {
	vapply(type, function(t) {
		switch(t,
			`16-bit integer` = 2L,
			`32-bit integer` = 4L,
			`64-bit integer` = 8L,
			`32-bit float` = 4L,
			`64-bit float` = 8L,
			stop("unrecognized binary type"))
	}, integer(1))
}

Ctypeof <- function(type) {
	vapply(type, function(t) {
		switch(t,
			`16-bit integer` = "short",
			`32-bit integer` = "int",
			`64-bit integer` = "long",
			`32-bit float` = "float",
			`64-bit float` = "double",
			stop("unrecognized binary type"))
	}, character(1))
}

## Coerce to a supported matrix-like array object
as.matrixlike <- function(x, supported="matrix") {
	err <- function(e) .stop("this function supports only in-memory R matrices")
	if ( any(sapply(supported, is, object=x)) ) {
		x
	} else {
		tryCatch(as.matrix(x), error=err)
	}
}

## Make an annotation (factor) from regions-of-interest (logical)
make.annotation <- function(...) {
	regions <- data.frame(...)
	names <- names(regions)
	x <- as.character(rep(NA, nrow(regions)))
	for ( nm in names ) {
		x[regions[[nm]]] <- nm
	}
	if ( length(regions) == 1 ) {
		x[is.na(x)] <- paste("NOT", names[1])
	}
	as.factor(x)
}

## Match methods to their workhorse functions
match.method <- function(method, options) {
	if ( is.function(method) ) {
		tryCatch(deparse(substitute(method, env=parent.frame())),
			error = function(e) "unknown")
	} else if ( is.character(method) && missing(options) ) {
		method[1]
	} else if ( is.character(method) ) {
		matched <- pmatch(method[1], options)
		if ( is.na(matched) ) {
			method[1]
		} else {
			options[matched]
		}
	} else if ( is.null(method) ) {
		options[1]
	} else {
		"<unknown>"
	}
}

## Programmatic friendly version of base::subset
subdata <- function(data, subset, select, drop=FALSE) {
	subset <- subrows(data, subset=subset)
	data[subset,select,drop=drop]
}

## Programmatic friendly version of base::subset (only return row indices)
subrows <- function(data, subset) {
	subset <- sapply(seq_along(subset), function(i) {
		data[[names(subset)[[i]]]] %in% subset[[i]]
	})
	if ( is.null(dim(subset)) ) {
		which(subset)
	} else {
		which(apply(subset, 1, all))
	}
}

## Evaluate a function after capturing unwanted ... arguments
wrap <- function(exprs, ..., signature) {
	.local <- function() {
		eval(substitute(exprs, env=parent.frame()))
	}
	environment(.local) <- parent.frame()
	if ( is.function(signature) ) {
		formals(.local) <- formals(signature)
	} else {
		formals(.local) <- signature
	}
	.local(...)
}

## Saves the current .Random.seed
save.seed <- function() {
	.Cardinal$.Random.seed <- get(".Random.seed", envir=globalenv())
}

## Restores the saved .Random.seed
restore.seed <- function() {
	assign(".Random.seed", .Cardinal$.Random.seed, envir=globalenv())
}
