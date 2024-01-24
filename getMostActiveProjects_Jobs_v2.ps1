$rd_host = "lseg-oss:4440/api/24"
$endpoint = "projects"
$token = "SBEpxApTTwd5ikaHfpJ4sHnrUu7aPhSj"

$headers = @{
    "Accept" = "application/json"
    "X-Rundeck-Auth-Token" = $token
}

#Write-Host "Starting to get projects from $rd_host"

$url = "http://$rd_host/$endpoint"
$response = Invoke-RestMethod -Uri $url -Method Get -Headers $headers 

#$response

# Hashtable to store project names and data
$projectDictionary = @{}

# Iterate through each project in the response
Write-Host "Processing projects..."
foreach ($project in $response) {

    $projectName = $project.name
    #Write-Host "Processing project: $projectName"

    $execFilter = "1d"

     # Construct the URL for the new request based on the project name
     $projectUrl = "http://$rd_host/project/$projectName/executions?recentFilter=$execFilter"

     # Perform another HTTP request for each project
     $execInfoResponse = Invoke-RestMethod -Uri $projectUrl -Method Get -Headers $headers
 
     # Add the project Name and Total Execs to the hashtable
     $projectDictionary[$projectName] = @{
         "TotalExecutions" = $execInfoResponse.paging.total
     }

     #Poll jobs and get executions per job
    $jobsUrl = "http://$rd_host/project/$projectName/jobs"

    $jobsResponse = Invoke-RestMethod -Uri $jobsUrl -Method Get -Headers $headers

    Write-Host "Processing jobs..."
    foreach($job in $jobsResponse) {
        $jobId = $job.id
        $jobName = $job.name

        $jobExecsUrl =  "http://$rd_host/project/$projectName/executions?recentFilter=$execFilter&jobIdListFilter=$jobId"

        $jobExecsResponse = Invoke-RestMethod -Uri $jobExecsUrl -Method Get -Headers $headers

        $jobTotalExecs = $jobExecsResponse.paging.total
        #Write-Host "Total execs for $jobId - $jobTotalExecs"
        $projectDictionary[$projectName][$jobName] = $jobTotalExecs
    }
}

# Display the array of project IDs
$sortedProjects = $projectDictionary.GetEnumerator() | Sort-Object { $_.Value['TotalExecutions'] } -Descending

Write-Host "Project Totals:"
$sortedProjects | Format-Table