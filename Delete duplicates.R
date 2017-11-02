
# Login to Salesforce ---------------------------------------------------------------

library(RForcecom)
username <- "admin@utzmars.org"
password <- "gfutzmars2017**oyCqeCwuJQCCfOBACJKmKOIr8"
session <- rforcecom.login(username, password)


# Retrieve data to delete -----------------------------------------------------------

# Vector of objects to download
objects.del <- c("AODiagnostic__c", "GPS_Point__c", "Other_crops__c", "Family_members__c",
                 "farmer__c", "Farm__c")
# Retrieve objects data
for(i in seq_along(objects.del)) {
      # Retrieve data
      assign(paste("del.", objects.del[i], sep = ""), 
             rforcecom.retrieve(session, objects.del[i], "Id"))
      # Create list with names of data frames created
      temp <- paste("del.", objects.del[i], sep = "")
      ifelse(exists("del.list") == FALSE, del.list <- temp, del.list[i] <- temp)
      rm(temp)
}


# Delete data -----------------------------------------------------------------------

# Delete records retrieved
for(i in seq_along(del.list)) {
      if(NROW(get(del.list[i])) > 0) {
            # Delete records
            job_info <- rforcecom.createBulkJob(session, 
                                                operation='delete', 
                                                object= objects.del[i])
            
            batches_info <- rforcecom.createBulkBatch(session, 
                                                      jobId=job_info$id, 
                                                      get(del.list[i]), 
                                                      multiBatch = TRUE, 
                                                      batchSize = 100)
            
            # # Batches status
            # batches_status <- lapply(batches_info, 
            #                          FUN=function(x){
            #                                rforcecom.checkBatchStatus(session, 
            #                                                           jobId=x$jobId, 
            #                                                           batchId=x$id)
            #                          })
            # status <- c()
            # records.processed <- c()
            # records.failed <- c()
            # for(i in 1:length(batches_status)) {
            #       status[i] <- batches_status[[i]]$state
            #       records.processed[i] <- batches_status[[i]]$numberRecordsProcessed
            #       records.failed[i] <- batches_status[[i]]$numberRecordsFailed
            # }
            # data.frame(status, records.processed, records.failed)
            # 
            # 
            # # Batches details
            # batches_detail <- lapply(batches_info, 
            #                          FUN=function(x){
            #                                rforcecom.getBatchDetails(session, 
            #                                                          jobId=x$jobId, 
            #                                                          batchId=x$id)
            #                          })
            
            # Close job
            close_job_info <- rforcecom.closeBulkJob(session, jobId=job_info$id)
      }
}


# Update records for real farmers ---------------------------------------------------

# Retrieve FDP submissions
fdp.sub <- rforcecom.retrieve(session, "FDP_submission__c", c("Id", "farmerCode__c"))

# Update FDP submissions
job_info <- rforcecom.createBulkJob(session, 
                                    operation='update', 
                                    object= 'FDP_submission__c')

batches_info <- rforcecom.createBulkBatch(session, 
                                          jobId=job_info$id, 
                                          fdp.sub, 
                                          multiBatch = TRUE, 
                                          batchSize = 20)

# Batches status
batches_status <- lapply(batches_info,
                         FUN=function(x){
                               rforcecom.checkBatchStatus(session,
                                                          jobId=x$jobId,
                                                          batchId=x$id)
                         })
status <- c()
records.processed <- c()
records.failed <- c()
for(i in 1:length(batches_status)) {
      status[i] <- batches_status[[i]]$state
      records.processed[i] <- batches_status[[i]]$numberRecordsProcessed
      records.failed[i] <- batches_status[[i]]$numberRecordsFailed
}
data.frame(status, records.processed, records.failed)


# Batches details
batches_detail <- lapply(batches_info,
                         FUN=function(x){
                               rforcecom.getBatchDetails(session,
                                                         jobId=x$jobId,
                                                         batchId=x$id)
                         })

# Close job
close_job_info <- rforcecom.closeBulkJob(session, jobId=job_info$id)
