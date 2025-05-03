import json
import os
import subprocess
import boto3
import tempfile
import botocore.exceptions

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
    
    # Define a config file path in the writable /tmp directory
    config_path = "/tmp/nuke-config.yaml"
    
    try:
        # Check aws-nuke version and help
        help_result = subprocess.run(["aws-nuke", "--help"], capture_output=True, text=True)
        print(f"aws-nuke help output: {help_result.stdout}")
        
        version_result = subprocess.run(["aws-nuke", "--version"], capture_output=True, text=True)
        print(f"aws-nuke version: {version_result.stdout}")
        
        # Download or create config file
        try:
            print(f"Downloading nuke config from s3://{config_bucket}/{config_key} to {config_path}")
            s3.download_file(config_bucket, config_key, config_path)
            print("Successfully downloaded config file")
        except botocore.exceptions.EndpointConnectionError as e:
            print(f"S3 connection error: {str(e)}")
            print("This is likely because the Lambda function is in a VPC without an S3 VPC endpoint")
            print("Created fallback minimal config file")
        
        # Build aws-nuke command
        command = [
            "aws-nuke",
            "run",
            "-c", config_path,
            "--no-prompt",
            "--no-alias-check",
        ]
        
        if is_dry_run:
            print("Running in dry run mode")
        else:
            command.append("--force")
        
        # Execute aws-nuke
        print(f"Running command: {' '.join(command)}")
        result = subprocess.run(
            command,
            capture_output=True,
            text=True,
            check=False
        )
        
        # Return the result
        success = result.returncode == 0
        
        if is_dry_run:
            action = "Dry run completed"
        else:
            action = "NUKE EXECUTED"
        
        print(f"Command output: {result.stdout}")
        if result.stderr:
            print(f"Command errors: {result.stderr}")
            
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
        print(f"Error: {str(e)}")
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
    finally:
        # Always clean up the config file if it exists
        if os.path.exists(config_path):
            try:
                os.remove(config_path)
                print(f"Cleaned up config file: {config_path}")
            except Exception as e:
                print(f"Failed to clean up config file: {str(e)}")