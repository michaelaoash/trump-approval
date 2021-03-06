## pdf(file="plots/How-Trump-Approval-Compares.pdf", paper="USr", height=0, width=0)
png(file="plots/How-Trump-Approval-Compares-%d.png", width=1024, height=768)
library(tidyverse)
library(googlesheets4)

rm(list=ls())

presidential_approval = data.frame()


## Replace googlesheets4 code as needed
## library(readxl)
## presidents  <- excel_sheets("American Presidency Project - Approval Ratings for POTUSxlsx")
## presidential_approval = bind_rows(presidential_approval, cbind( read_xlsx("American Presidency Project - Approval Ratings for POTUSxlsx", sheet=president,col_type=c("guess","guess","guess","guess","text")), tibble(president)  ))

presidents  <- pull(gs4_get("https://docs.google.com/spreadsheets/d/1iEl565M1mICTubTtoxXMdxzaHzAcPTnb3kpRndsrfyY/edit#gid=0")$sheets[,1])

## https://www.presidency.ucsb.edu/statistics/data/presidential-job-approval
for(president in presidents) {
    presidential_approval = bind_rows(presidential_approval,
                                      cbind( read_sheet("https://docs.google.com/spreadsheets/d/1iEl565M1mICTubTtoxXMdxzaHzAcPTnb3kpRndsrfyY/edit#gid=0",sheet=president), tibble(president) ))
}

presidential_approval  <- arrange(presidential_approval, as.Date(`End Date`))

    
## ## Ad hoc update
## ## Check manually if new data at https://news.gallup.com/poll/203198/presidential-approval-ratings-donald-trump.aspx
## ## and enter below
## presidential_approval = bind_rows(presidential_approval,tibble(`Start Date`=as.Date("2020-07-01"), `End Date`=as.Date("2020-07-23"), Approving=41, Disapproving=56, `Unsure/NoData`=3, president="Donald Trump"))

## Stretch the most recent Gallup poll data to today.
stretch  <- tibble(`Start Date`=as.Date(last(presidential_approval$`End Date`)), `End Date`=Sys.Date(), Approving=NA, Disapproving=NA, `Unsure/NoData`=NA, president=NA, filled=TRUE)

if (last(presidential_approval$`End Date`) < Sys.Date()) {
    presidential_approval  <- fill(bind_rows(presidential_approval, stretch), Approving, Disapproving, `Unsure/NoData`, president)
}


## UCSB corrected typo in Barack Obama's name on the Google Sheet
presidential_approval  <- mutate(presidential_approval,
                                 president = ifelse(president=="Barak Obama","Barack Obama",
                                             ifelse(president=="Harry S. Truman","Harry S Truman",
                                             ifelse(president=="George Bush","George H. W. Bush",                                                    
                                                    president)))
                                             )

presidents[which(presidents=="Barak Obama")] = "Barack Obama"
presidents[which(presidents=="Harry S. Truman")] = "Harry S Truman"
presidents[which(presidents=="George Bush")] = "George H. W. Bush"


## https://www.thegreenpapers.com/Hx/PresidentialElectionEvents.phtml
## https://historyinpieces.com/research/presidential-inauguration-dates
date_of_election  <- read_csv(file=
'election_date, postwar,incumbency, incumbent, Outcome, next_inauguration
1928-11-06,FALSE,FALSE,,,1929-03-04
1932-11-08,FALSE,TRUE,"Herbert Hoover","Not Reelected",1933-03-04
1936-11-03,FALSE,TRUE,"Franklin D. Roosevelt",Reelected,1937-01-20
1940-11-05,FALSE,TRUE,"Franklin D. Roosevelt",Reelected,1941-01-20
1944-11-07,FALSE,TRUE,"Franklin D. Roosevelt",Reelected,1945-01-20
1948-11-02,TRUE,TRUE,"Harry S Truman",Reelected,1949-01-20
1952-11-04,TRUE,FALSE,,,1953-01-20
1956-11-06,TRUE,TRUE,"Dwight D. Eisenhower",Reelected,1957-01-21
1960-11-08,TRUE,FALSE,,,1961-01-20
1964-11-03,TRUE,TRUE,"John F. Kennedy","Not Reelected",1965-01-20
1964-11-03,TRUE,TRUE,"Lyndon B. Johnson",Reelected,1965-01-20
1968-11-05,TRUE,FALSE,,,1969-01-20
1972-11-07,TRUE,TRUE,"Richard Nixon",Reelected,1973-01-20
1976-11-02,TRUE,TRUE,"Gerald R. Ford","Not Reelected",1977-01-20
1980-11-04,TRUE,TRUE,"Jimmy Carter","Not Reelected",1981-01-20
1984-11-06,TRUE,TRUE,"Ronald Reagan",Reelected,1985-01-21
1988-11-08,TRUE,FALSE,,,1989-01-20
1992-11-03,TRUE,TRUE,"George H. W. Bush","Not Reelected",1993-01-20
1996-11-05,TRUE,TRUE,"William J. Clinton",Reelected,1997-01-20
2000-11-07,TRUE,FALSE,,,2001-01-20
2004-11-02,TRUE,TRUE,"George W. Bush",Reelected,2005-01-20
2008-11-04,TRUE,FALSE,,,2009-01-20
2012-11-06,TRUE,TRUE,"Barack Obama",Reelected,2013-01-21
2016-11-08,TRUE,FALSE,,,2017-01-20
2020-11-03,TRUE,TRUE,"Donald Trump",,2021-01-20'
)

presidential_approval  <- left_join(presidential_approval, date_of_election, by=c("president"="incumbent"))

presidential_approval  <- mutate(presidential_approval,
                                 days_to_election = as.numeric(as.Date(`End Date`) - as.Date(election_date)),
                                 days_to_next_inaug = as.numeric(as.Date(`End Date`) - as.Date(next_inauguration)),
                                 `Net Approval` = Approving - Disapproving
                                 )


## ggplot(presidential_approval, aes(x = `End Date`, y= Approving))  + geom_line()  + facet_wrap(facets = ~ president, scales="free_x" )

trump_approval  <- filter(presidential_approval, president=="Donald Trump")
trump_approval  <-  crossing ( trump_approval, data.frame(president_merge=presidents))

test  <- full_join(presidential_approval, trump_approval, by=c("days_to_election","president"="president_merge"), suffix=c("",".trump")  ) %>% arrange(president, days_to_election)


test2  <- filter(test, days_to_next_inaug <= 0 | is.na(days_to_next_inaug) , president %in% c("Barack Obama","George W. Bush","William J. Clinton", "George H. W. Bush","Ronald Reagan","Jimmy Carter","Gerald R. Ford","Richard Nixon","Lyndon B. Johnson","John F. Kennedy","Dwight D. Eisenhower", "Harry S Truman" ) )



test2  <- mutate(test2,
                 president = factor(president,levels=
                                                  c("Barack Obama","Donald Trump", "George W. Bush","William J. Clinton", "George H. W. Bush","Ronald Reagan","Jimmy Carter","Gerald R. Ford","Richard Nixon","Lyndon B. Johnson","John F. Kennedy", "Dwight D. Eisenhower", "Harry S Truman")))

##View(select(test2,days_to_election, president, Approving, Approving.trump) )


(today  <- Sys.Date())
(last_poll_date  <- max(filter(presidential_approval, president=="Donald Trump", is.na(filled))$`End Date`))
(trump_election_date  <- max(filter(presidential_approval, president=="Donald Trump")$election_date))
(last_poll_days_to_election  <- as.numeric(as.Date(trump_election_date)) - as.numeric(as.Date(last_poll_date)))
(today_days_to_election  <- as.numeric(as.Date(trump_election_date)) - as.numeric(as.Date(today)))


mySubtitle = paste("Last poll (",last_poll_date,"): ", last_poll_days_to_election, " Days to election. ",
                   "This version (", Sys.Date(), "): ", today_days_to_election, " Days to election.", sep="" )


ggplot(test2, aes(x=days_to_election) ) + geom_step(data=filter(test2, !is.na(Approving)),aes(y=Approving,linetype=Outcome,group=president)) +
    geom_step(data=filter(test2, !is.na(Approving.trump)),aes(y=Approving.trump),color="green") + facet_wrap(facets = ~ president) + scale_x_continuous(breaks=c(-1095,-730,-365,-180,-90,0)) +
    labs(title="Trump (Green) Gallup Approval Compared to Previous Incumbent Presidents", subtitle=mySubtitle, x="Days to Re-Election Attempt") +
    geom_hline(yintercept=50,color="gray") + geom_vline(xintercept=0,color="gray") +
    theme(axis.text.x = element_text(angle = 60, hjust=1), legend.position="bottom")

ggplot(test2, aes(x=days_to_election) ) + geom_step(data=filter(test2, !is.na(Disapproving)),aes(y=Disapproving,linetype=Outcome,group=president)) +
    geom_step(data=filter(test2, !is.na(Disapproving.trump)),aes(y=Disapproving.trump),color="orange") + facet_wrap(facets = ~ president) + scale_x_continuous(breaks=c(-1095,-730,-365,-180,-90,0)) + scale_y_reverse() +
   labs(title="Trump (Orange) Gallup Disapproval Compared to Previous Incumbent Presidents (Downward is more disapproval.)", subtitle=mySubtitle, x="Days to Re-Election Attempt") +
    geom_hline(yintercept=50,color="gray") + geom_vline(xintercept=0,color="gray") +
    theme(axis.text.x = element_text(angle = 60, hjust=1), legend.position="bottom")


ggplot(test2, aes(x=days_to_election) ) + geom_step(data=filter(test2, !is.na(`Unsure/NoData`)),aes(y=`Unsure/NoData`,linetype=Outcome,group=president)) +
    geom_step(data=filter(test2, !is.na(`Unsure/NoData.trump`)),aes(y=`Unsure/NoData.trump`),color="purple") + facet_wrap(facets = ~ president) + scale_x_continuous(breaks=c(-1095,-730,-365,-180,-90,0)) +
    labs(title="Trump (Purple) Gallup Unsure Compared to Previous Incumbent Presidents", subtitle=mySubtitle, x="Days to Re-Election Attempt") +
    geom_vline(xintercept=0,color="gray") +
    theme(axis.text.x = element_text(angle = 60, hjust=1), legend.position="bottom")


ggplot(test2, aes(x=days_to_election) ) + geom_step(data=filter(test2, !is.na(`Net Approval`)),aes(y=`Net Approval`,linetype=Outcome,group=president)) +
    geom_step(data=filter(test2, !is.na(`Net Approval.trump`)),aes(y=`Net Approval.trump`),color="blue") + facet_wrap(facets = ~ president) + scale_x_continuous(breaks=c(-1095,-730,-365,-180,-90,0)) +
    labs(title="Trump (Blue) Gallup Net Approval Compared to Previous Incumbent Presidents", subtitle=mySubtitle, x="Days to Re-Election Attempt") +
    geom_hline(yintercept=0,color="gray") + geom_vline(xintercept=0,color="gray") +
    theme(axis.text.x = element_text(angle = 60, hjust=1), legend.position="bottom")

