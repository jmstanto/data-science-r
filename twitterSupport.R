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

# PrepareTwitter() - Load packages for working with twitteR
PrepareTwitter<-function()
{
  EnsurePackage("bitops")
  EnsurePackage("RCurl")
  EnsurePackage("RJSONIO")
  EnsurePackage("twitteR")
}

# TweetFrame() - Return a dataframe based on a search of Twitter
TweetFrame<-function(searchTerm, maxTweets)
{
  tweetList <- searchTwitter(searchTerm, n=maxTweets)
  
  # as.data.frame() coerces each list element into a row
  # lapply() applies this to all of the elements in twtList
  # rbind() takes all of the rows and puts them together
  # do.call() gives rbind() all the rows as individual elements
  tweetDF <- do.call("rbind", lapply(tweetList,as.data.frame))
  
  # This last step sorts the tweets in arrival order
  return(tweetDF[order(as.integer(tweetDF$created)), ])
}

# CleanTweets() - Takes the junk out of a vector of tweet texts
CleanTweets<-function(tweets)
{
  # Remove redundant spaces
  tweets <- str_replace_all(tweets,"  "," ")
  # Get rid of URLs
  tweets <- str_replace_all(tweets, "http://t.co/[a-z,A-Z,0-9]{8}","")
  # Take out retweet header, there is only one
  tweets <- str_replace(tweets,"RT @[a-z,A-Z]*: ","")
  tweets <- str_replace_all(tweets,"#[a-z,A-Z]*","")
  tweets <- str_replace_all(tweets,"@[a-z,A-Z]*","")
  return(tweets)
}

# ArrivalProbability - Given a list of arrival times
# calculates the delays between them with lagged differences
# then computes a list of cumulative probabilties of arrival
# for a list of time increments
# times - A sorted, ascending list of arrival times in POSIXct
# increment - the time increment for each new probability
# max - the highest time increment
#
# Returns - an ordered list of probabilities in a numeric vector
# suitable for plotting with plot()
ArrivalProbability<-function(times, increment, max)
{
  # Initialize an empty vector
  plist <- NULL
  
  # Probability is defined over the size of this sample
  # of arrival times
  timeLen <- length(times)
  
  # May not be necessary, but checks for input mistake
  if (increment>max) {return(NULL)}
  
  for (i in seq(increment, max, by=increment))
  {
    # diff() requires a sorted list of times
    # diff() calculates the delays between neighboring times
    # the logical test <i provides a list of TRUEs and FALSEs
    # of length = timeLen, then sum() counts the TRUEs
    plist<-c(plist,(sum(as.integer(diff(times))<i))/timeLen)
  }
  return(plist)
}

# Like ArrivalProbability, but works with an unsorted list
# of delay times
DelayProbability<-function(delays, increment, max)
{
  # Initialize an empty vector
  plist <- NULL
  
  # Probability is defined over the size of this sample
  # of arrival times
  delayLen <- length(delays)
  
  # May not be necessary, but checks for input mistake
  if (increment>max) {return(NULL)}
  
  for (i in seq(increment, max, by=increment))
  {
    # the logical test <i provides a list of TRUEs and FALSEs
    # of length = timeLen, then sum() counts the TRUEs
    plist<-c(plist,(sum(delays<=i)/delayLen))
  }
  return(plist)
}

# Compare tweets - Run poisson.test() on rate ratio for two tweet streams
# search1 - the first hashtag or search twerm to look for
# search2 - the second search term or hashtag to look for
# numEvents - the number of events to sample for each search
CompareTweets <- function(search1, search2, numEvents)
{
  tweetDF <- TweetFrame(search1, numEvents)
  sortweetDF<-tweetDF[order(as.integer(tweetDF$created)), ] 
  eventDelays1 <- as.integer(diff(sortweetDF$created))
  meanDelays1 <- round(mean(eventDelays1))
  
  tweetDF <- TweetFrame(search2, numEvents)
  sortweetDF<-tweetDF[order(as.integer(tweetDF$created)), ] 
  eventDelays2 <- as.integer(diff(sortweetDF$created))
  
  eventCount1 <- sum(eventDelays1<=meanDelays1)
  eventCount2 <- sum(eventDelays2<=meanDelays1)
  
  return(poisson.test(c(eventCount1,eventCount2),c(numEvents,numEvents)))
}