# Define key column.
ZIP.code <- "ZIP.code"

# Define IRS column names.
average.income <- "average.income"
income.no.outliers <- "income.no.outliers"
return.count <- "return.count"
total.income <- "total.income"

# Define NYC column names.
black.count <- "black.count"
hispanic.count <- "hispanic.count"
white.count <- "white.count"

# Percentage columns
percent.black <- "percent.black"
percent.hispanic <- "percent.hispanic"
percent.white <- "percent.white"

# Read IRS data and rename columns.
income.data <- read.csv(file = "IRS/nyc_no_agi.csv", header = TRUE, sep = ",")
colnames(income.data)[colnames(income.data) == "N02650"] <- return.count
colnames(income.data)[colnames(income.data) == "A02650"] <- total.income
colnames(income.data)[colnames(income.data) == "ZIPCODE"] <- ZIP.code

# Remove non-essential columns from IRS data, and calculate average income.
income.data <- income.data[c(return.count, total.income, ZIP.code)]
income.data[average.income] = income.data[total.income] * 1000. / income.data[return.count]

# Read NYC data and rename columns.
demographic.data <- read.csv(file = "NYC/Demographic_Statistics_By_Zip_Code.csv",
                             header = TRUE, sep = ",")
colnames(demographic.data)[colnames(demographic.data)=="COUNT.BLACK.NON.HISPANIC"] <- black.count
colnames(demographic.data)[colnames(demographic.data)=="COUNT.HISPANIC.LATINO"] <- hispanic.count
colnames(demographic.data)[colnames(demographic.data)=="COUNT.WHITE.NON.HISPANIC"] <- white.count
colnames(demographic.data)[colnames(demographic.data)=="JURISDICTION.NAME"] <- ZIP.code

# Remove non-essential columns from NYC data.
demographic.data <- demographic.data[c(black.count, hispanic.count, white.count, ZIP.code)]

# Create pairing datasets.
merged.data <- merge(demographic.data, income.data, by=c(ZIP.code))
black.and.hispanic <- subset(merged.data,
                             merged.data$black.count != 0 | merged.data$hispanic.count != 0)
black.and.white <- subset(merged.data,
                          merged.data$black.count != 0 | merged.data$white.count != 0)
hispanic.and.white <- subset(merged.data,
                             merged.data$hispanic.count != 0 | merged.data$white.count != 0)

# Declare percentage function.
determine.percentage <- function(numerator, other) {
  return (numerator / (numerator + other))
}

# Define percentages for black and hispanic.
black.and.hispanic[percent.black] = determine.percentage(black.and.hispanic$black.count,
                                                         black.and.hispanic$hispanic.count)
black.and.hispanic[percent.hispanic] = 1. - black.and.hispanic$percent.black

# Define percentages for black and white.
black.and.white[percent.black] = determine.percentage(black.and.white$black.count,
                                                      black.and.white$white.count)
black.and.white[percent.white] = 1. - black.and.white$percent.black

# Define percentages for hispanic and white.
hispanic.and.white[percent.hispanic] = determine.percentage(hispanic.and.white$hispanic.count,
                                                            hispanic.and.white$white.count)
hispanic.and.white[percent.white] = 1. - hispanic.and.white$percent.hispanic

# White vs. Black
black.vs.white.model <- lm("average.income ~ percent.white", black.and.white)
summary(black.vs.white.model)

plot(black.and.white$percent.white,
     black.and.white$average.income, main="Income White vs. Black Percentage", 
     xlab="Percent White", ylab="Average Income")
abline(black.vs.white.model, col = "red")

# White vs. Hispanic
hispanic.vs.white.model <- lm("average.income ~ percent.white", hispanic.and.white)
summary(hispanic.vs.white.model)

plot(hispanic.and.white$percent.white,
     hispanic.and.white$average.income, main="Income White vs. Hispanic Percentage", 
     xlab="Percent White", ylab="Average Income")
abline(hispanic.vs.white.model, col = "green")

# Hispanic vs. Black
black.vs.hispanic.model <- lm("average.income ~ percent.hispanic", black.and.hispanic)
summary(black.vs.hispanic.model)

plot(black.and.hispanic$percent.hispanic,
     black.and.hispanic$average.income, main="Income Hispanic vs. Black Percentage", 
     xlab="Percent Hispanic", ylab="Average Income")
abline(black.vs.hispanic.model, col = "blue")

# Define function to remove outliers.
remove_outliers <- function(x, na.rm = TRUE, ...) {
  
  # qnt <- quantile(x, probs=c(.25, .75), na.rm = na.rm, ...)
  qnt <- quantile(x, probs=c(.25, .75), na.rm = na.rm, ...)
  H <- 1.5 * IQR(x, na.rm = na.rm)
  y <- x
  y[x < (qnt[1] - H)] <- NA
  y[x > (qnt[2] + H)] <- NA
  y
}

# Remove income outliers.
black.and.white$income.no.outliers <- remove_outliers(black.and.white$average.income)
hispanic.and.white$income.no.outliers <- remove_outliers(hispanic.and.white$average.income)
black.and.hispanic$income.no.outliers <- remove_outliers(black.and.hispanic$average.income)

# Let's say say something about the income outliers...
interest.columns <- c(ZIP.code,
                      black.count,
                      hispanic.count,
                      white.count,
                      average.income,
                      income.no.outliers)

black.and.white[is.na(black.and.white$income.no.outliers), interest.columns]
black.and.hispanic[is.na(black.and.hispanic$income.no.outliers), interest.columns]
hispanic.and.white[is.na(hispanic.and.white$income.no.outliers), interest.columns]

# Try modeling without income outliers...White vs. Black
black.vs.white.model <- lm("income.no.outliers ~ percent.white", black.and.white)
summary(black.vs.white.model)

plot(black.and.white$percent.white,
     black.and.white$income.no.outliers, main="Income White vs. Black Percentage", 
     xlab="Percent White", ylab="Average Income without Outliers")
abline(black.vs.white.model, col = "red")

# White vs. Hispanic
hispanic.vs.white.model <- lm("income.no.outliers ~ percent.white", hispanic.and.white)
summary(hispanic.vs.white.model)

plot(hispanic.and.white$percent.white,
     hispanic.and.white$income.no.outliers, main="Income White vs. Hispanic Percentage", 
     xlab="Percent White", ylab="Average Income without Outliers")
abline(hispanic.vs.white.model, col = "green")

# Hispanic vs. Black
black.vs.hispanic.model <- lm("income.no.outliers ~ percent.hispanic", black.and.hispanic)
summary(black.vs.hispanic.model)

plot(black.and.hispanic$percent.hispanic,
     black.and.hispanic$income.no.outliers, main="Income Hispanic vs. Black Percentage", 
     xlab="Percent Hispanic", ylab="Average Income without Outliers")
abline(black.vs.hispanic.model, col = "blue")
