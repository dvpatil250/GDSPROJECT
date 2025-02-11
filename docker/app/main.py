import boto3
import psycopg2
import pandas as pd
import os
import json
from botocore.exceptions import NoCredentialsError

# AWS Clients
s3 = boto3.client("s3")
glue = boto3.client("glue")

# Environment Variables (Ensure These Are Set in Lambda)
DB_HOST = os.getenv("DB_HOST")
DB_NAME = os.getenv("DB_NAME")
DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")
GLUE_DATABASE = os.getenv("GLUE_DATABASE")

def read_data_from_s3(bucket_name, object_key):
    """Reads CSV file from S3 and returns a DataFrame"""
    try:
        print(f"Reading from S3: Bucket={bucket_name}, Key={object_key}")

        response = s3.get_object(Bucket=bucket_name, Key=object_key)
        df = pd.read_csv(response["Body"])
        print("Data read successfully from S3.")
        print(df.head())  # Print first few rows for debugging

        return df

    except NoCredentialsError:
        print("AWS credentials not available.")
        return None
    except Exception as e:
        print(f"Error reading from S3: {e}")
        return None

def push_to_rds(df):
    """Pushes DataFrame to RDS PostgreSQL"""
    try:
        print("Connecting to RDS...")
        conn = psycopg2.connect(
            host=DB_HOST,
            database=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD
        )
        cursor = conn.cursor()

        for _, row in df.iterrows():
            cursor.execute("INSERT INTO your_table (column1, column2) VALUES (%s, %s)", (row['column1'], row['column2']))

        conn.commit()
        cursor.close()
        conn.close()

        print("Data pushed to RDS successfully.")
        return True
    except Exception as e:
        print(f"Failed to push to RDS: {e}")
        return False

def push_to_glue(df, bucket_name):
    """Pushes DataFrame to S3 (Glue fallback)"""
    try:
        glue_path = f"s3://{bucket_name}/s3_fallback_table.csv"
        df.to_csv(glue_path, index=False)
        print(f"Data pushed to Glue at {glue_path}")
    except Exception as e:
        print(f"Failed to push to Glue: {e}")

def lambda_handler(event, context):
    """Lambda function triggered by S3 event"""
    print("Lambda function triggered by S3 event.")

    # Extract bucket name and object key from the event
    try:
        records = event.get("Records", [])
        if not records:
            raise ValueError("No records found in event.")

        for record in records:
            bucket_name = record["s3"]["bucket"]["name"]
            object_key = record["s3"]["object"]["key"]

            print(f"Processing file: {object_key} from bucket: {bucket_name}")

            # Read data from S3
            df = read_data_from_s3(bucket_name, object_key)
            if df is not None:
                # Try to push to RDS, if fails, push to Glue
                if not push_to_rds(df):
                    push_to_glue(df, bucket_name)

    except Exception as e:
        print(f"Error processing event: {e}")

    print("Lambda execution complete.")
    return {
        "statusCode": 200,
        "body": json.dumps("Lambda execution complete.")
    }

