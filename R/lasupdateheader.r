lasupdateheader = function(las)
{
  stopifnotlas(las)

  header = as.list(las@header)
  new_header = rlas::header_update(header, las@data)
  new_header = LASheader(new_header)
  C_lasupdateheader(las, new_header)
  return(invisible())
}


#' Add data into a las object
#'
#' A LAS object represents a .las file in R. According the
#' \href{https://www.asprs.org/a/society/committees/standards/LAS_1_4_r13.pdf}{LAS specifications}
#' a las file contains a core of defined variables such as XYZ coordinates, intensity, return number
#' and so on for each point. It is possible to add supplementary data. The functions \code{lasadd*}
#' enable the user to add new data (see details)
#'
#' \code{lasadddata} simply adds a new column in the data but does not update the header. Thus the LAS
#' object is not strictly valid. These data will be usable at the R level but will not be written in a
#' las file with \link{writeLAS}.\cr\cr
#' \code{lasaddextrabyte} do the same than \code{lasadddata} but updates automatically the header of the
#' LAS object. Thus, the LAS obejct is valid and the new data is considered as "extra bytes". This new
#' data will be written in a las file with \link{writeLAS}\cr\cr
#' \code{lasaddextrabyte_manual} allows the user to manually write all the extra bytes information.
#' This fonction is reserved for experienced user with a good knowledge of the LAS specifications.
#' The function does not perform tests to check the validy of the informations.
#'
#' @param las an object of class LAS
#' @param x a vector that need to be added in the LAS object. If missing, the colum \code{'name'} of
#' the existing LAS object will be used.
#' @param name character. The name of the extrabytes attributes to add in the file.
#' @param desc character. As short description of the extrabytes attributes to add in the file.
#' @param type character. The data type of the extra bytes attribute. Can be \code{"uchar", "char", "ushort",
#' "short", "uint", "int", "uint64", "int64", "float", "double"}
#' @param scale,offset numeric. The scale and offset of the data. NULL if not relevant.
#' @param NA_value numeric or integer. NA is not a valid value in a las file. At writting time it will
#' be replace by this value that will be considered as NA. NULL if not relevant.
#'
#' @return Nothing (NULL). The LAS object is updated in place by reference to avoid copies.
#' @export
#' @examples
#' LASfile <- system.file("extdata", "example.laz", package="rlas")
#' las = readLAS(LASfile)
#'
#' print(las)
#' print(las@header)
#'
#' x= 1:30
#'
#' lasadddata(las, x, "mydata")
#' print(las) # The las object has a new field called "mydata"
#' print(las@header) # But the header has not been updated. This new data will not be written
#'
#' lasaddextrabytes(las, x, "mydata2", "A new data")
#' print(las) # The las object has a new field called "mydata2"
#' print(las@header) # The header has not been updated. This new data will be written
#'
#' # optionnaly if the data is already in the LAS object you can update the header skiping the
#' # parameter x
#' lasaddextrabytes(las, name ="mydata", desc = "Amplitude")
#' print(las@header)
lasadddata = function(las, x, name)
{
  stopifnotlas(las)
  stopifnot(is.character(name), is.vector(x))
  las@data[, (name) := x]
  return(invisible())
}

#' @export
#' @rdname lasadddata
lasaddextrabytes = function(las, x, name, desc)
{
  stopifnot(is.character(name), is.character(desc))

  if (missing(x))
    x = las@data[[name]]
  else
    lasadddata(las, x, name)

  header = as.list(las@header)
  header = rlas::header_add_extrabytes(header, x, name, desc)
  header = LASheader(header)
  C_lasupdateheader(las, header)

  return(invisible())
}

#' @export
#' @rdname lasadddata
lasaddextrabytes_manual = function(las, x, name, desc, type, offset = NULL, scale = NULL, NA_value = NULL)
{
  stopifnot(is.character(name), is.character(desc), is.character(type))

  allowed = c("uchar", "char", "ushort", "short", "uint", "int", "uint64", "int64", "float", "double")
  type = which(allowed == type) - 1

  if(length(type) == 0)
    stop("Invalide type", call. = FALSE)

  if (missing(x))
    x = las@data[[name]]
  else
    lasadddata(las, x, name)

  header = as.list(las@header)
  header = rlas::header_add_extrabytes_manual(header, name, desc, type, offset, scale, min(x, na.rm = TRUE), max(x, na.rm = TRUE), NA_value)
  header = LASheader(header)
  C_lasupdateheader(las, header)

  return(invisible())
}

# type = 0 : unsigned char
# type = 1 : char
# type = 2 : unsigned short
# type = 3 : short
# type = 4 : unsigned int
# type = 5 : int
# type = 6 : unsigned int64
# type = 7 : int64
# type = 8 : float  (try not to use)
# type = 9 : double (try not to use)