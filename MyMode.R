MyMode <- function(myVector)
{
  uniqueValues <- unique(myVector)
  uniqueCounts <- tabulate(match(myVector,uniqueValues))
  
  return(uniqueValues[which.max(uniqueCounts)])
}