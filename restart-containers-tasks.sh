#!/bin/bash
set -e

# Grab the region
REGION=$1
CLUSTER=$2

# Check to see that the region maps out
if [ "${REGION}" = "" ]; 
then
    REGION="us-east-1"
fi

# Print the region

CLUSTER_LIST=$(aws ecs list-clusters --region $REGION )
CLUSTER_ARN_LIST=($(echo $CLUSTER_LIST | jq .clusterArns[]))

# Iterate through the tasks and pull out the ARN identifier for each task to stop if necessary
for CLUSTER_ID in "${CLUSTER_ARN_LIST[@]}"
do
:
    # Check to see if this is cluster we want
    if [[ $CLUSTER_ID != *"PART_OF_CLUSTER_NAME"* ]]
    then
        echo "Not a PART_OF_CLUSTER_NAME cluster $CLUSTER_ID"
        continue;
    fi

    # grab the identifier for our captured task
    CLUSTER_ID=${CLUSTER_ID##*/}

    # Remove " characters
    CLUSTER_ID="${CLUSTER_ID//\"}"

    echo $CLUSTER_ID

    TASK_LIST=$(aws ecs list-tasks --region $REGION --cluster $CLUSTER_ID )

    # Create an array of the tasks
    TASK_ARN_LIST=($(echo $TASK_LIST | jq .taskArns[]))

    # Iterate through the tasks and pull out the ARN identifier for each task to stop if necessary
    for RUNNING_TASK in "${TASK_ARN_LIST[@]}"
    do
    :
            if [[ "$RUNNING_TASK" == null || "$RUNNING_TASK" == "" ]]; then
                echo "Task is null, doing nothing"
            else

            # grab the identifier for our captured task
            TASK_ID=${RUNNING_TASK##*/}

            # Remove " characters
            TASK_ID="${TASK_ID//\"}"

            # Describe the task, lets look for our definition 
            taskInfo=$(aws ecs describe-tasks --region $REGION --tasks $TASK_ID --cluster $CLUSTER_ID)

            # Grab the task definition arn and look for our desired task identifier
            def=$(echo $taskInfo | jq .tasks[].taskDefinitionArn)

            #echo $def

            if [[ $def == *"PART_OF_TASK_NAME"* ]]
            then
                output=$(aws ecs stop-task --region $REGION --task $TASK_ID --cluster $CLUSTER_ID)
                echo "Found task identified as: $TASK_ID, stopping..."
            fi

        fi

    done

done
