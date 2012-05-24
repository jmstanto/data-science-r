# Mapping scripts
# EnsurePackage(x) - Installs and loads a package if necessary
EnsurePackage<-function(x)
{
  x <- as.character(x)
  if (!require(x,character.only=TRUE))
  {
    install.packages(pkgs=x,repos="http://cran.r-project.org")
    require(x,character.only=TRUE)
  }
}


# Format an URL for the Google Geocode API
MakeGeoURL <- function(address) 
{
  
  root <- "http://maps.google.com/maps/api/geocode/"
  
  url <- paste(root, "json?address=", address, "&sensor=false", sep = "")
  
  return(URLencode(url))
}

Addr2latlng <- function(address) 
{
  url <- MakeGeoURL(address)
  
  apiResult <- getURL(url)
  
  geoStruct <- fromJSON(apiResult, simplify = FALSE)
  
  lat <- NA
  lng <- NA
  
  
  try(lat <- geoStruct$results[[1]]$geometry$location$lat, silent=TRUE)
  try(lng <- geoStruct$results[[1]]$geometry$location$lng, silent=TRUE)
  
  return(c(lat, lng))
}

# Process a whole list of addresses
ProcessAddrList <- function(addrList)
{
  resultDF <- data.frame(atext=character(),X=numeric(),Y=numeric(),EID=numeric())
  i <- 1
  
  for (addr in addrList)
  {
    latlng = Addr2latlng(addr)
    resultDF <- rbind(resultDF, data.frame(atext=addr,X=latlng[[2]],Y=latlng[[1]], EID=i))
    i <- i + 1
  }
  
  return(resultDF)
}