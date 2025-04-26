import json
import os
import subprocess
import boto3
import tempfile

s3 = boto3.client('s3')

def handler(event, context):
    print("AWS Nuke Button triggered!")
    
    # Get configuration from environment variables
    config_bucket = os.environ['CONFIG_BUCKET']
    config_key = os.environ['CONFIG_KEY']
    target_account = os.environ['TARGET_ACCOUNT']
    
    # Check if this is a dry run or real execution
    path = event.get('requestContext', {}).get('http', {}).get('path', '')
    is_dry_run = '/dry-run' in path
    
    # Download config file from S3
    with tempfile.NamedTemporaryFile(delete=False) as temp_file:
        s3.download_file(config_bucket, config_key, temp_file.name)
        config_path = temp_file.name
    
    # Build aws-nuke command
    command = [
        "aws-nuke",
        "-c", config_path,
        "--target", target_account
    ]
    
    if is_dry_run:
        command.append("--no-dry-run=false")
    else:
        command.append("--no-dry-run=true")
        command.append("--force")  # Skip confirmation prompt
    
    try:
        # Execute aws-nuke
        result = subprocess.run(
            command,
            capture_output=True,
            text=True,
            check=False
        )
        
        # Clean up the temp file
        os.unlink(config_path)
        
        # Return the result
        success = result.returncode == 0
        
        if is_dry_run:
            action = "Dry run completed"
        else:
            action = "NUKE EXECUTED"
        
        return {
            "statusCode": 200 if success else 500,
            "body": json.dumps({
                "action": action,
                "success": success,
                "message": result.stdout,
                "errors": result.stderr
            }),
            "headers": {
                "Content-Type": "application/json"
            }
        }
    except Exception as e:
        return {
            "statusCode": 500,
            "body": json.dumps({
                "success": False,
                "message": f"Error: {str(e)}"
            }),
            "headers": {
                "Content-Type": "application/json"
            }
        }