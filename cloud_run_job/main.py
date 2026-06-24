import csv
import io
import os
import sys

from google.cloud import dlp_v2
from google.cloud import storage


def build_table_from_csv(csv_content: str) -> dlp_v2.types.Table:
    reader = csv.DictReader(io.StringIO(csv_content))
    headers = [dlp_v2.types.FieldId(name=field) for field in reader.fieldnames or []]
    rows = []

    for row in reader:
        values = [dlp_v2.types.Value(string_value=row.get(field, "")) for field in (reader.fieldnames or [])]
        rows.append({"values": values})

    return dlp_v2.types.Table(headers=headers, rows=rows)


def table_to_csv(table: dlp_v2.types.Table, output_field_names: list[str]) -> str:
    output = io.StringIO()
    writer = csv.DictWriter(output, fieldnames=output_field_names)
    writer.writeheader()

    for row in table.rows:
        writer.writerow({
            field.name: value.string_value
            for field, value in zip(table.headers, row.values)
        })

    return output.getvalue()


def run_job() -> None:
    project_id = os.environ.get("PROJECT_ID")
    if not project_id:
        raise RuntimeError("PROJECT_ID environment variable is required")

    landing_bucket_name = os.environ.get("LANDING_BUCKET")
    raw_bucket_name = os.environ.get("RAW_BUCKET")
    dlp_template_name = os.environ.get("DLP_TEMPLATE_NAME")

    if not landing_bucket_name or not raw_bucket_name or not dlp_template_name:
        raise RuntimeError("LANDING_BUCKET, RAW_BUCKET, and DLP_TEMPLATE_NAME must be set")

    storage_client = storage.Client(project=project_id)
    dlp_client = dlp_v2.DlpServiceClient()
    parent = f"projects/{project_id}"

    landing_bucket = storage_client.bucket(landing_bucket_name)
    raw_bucket = storage_client.bucket(raw_bucket_name)

    blobs = [blob for blob in landing_bucket.list_blobs() if blob.name.lower().endswith(".csv")]
    if not blobs:
        print("No CSV files found in the landing bucket.")
        return

    for blob in blobs:
        print(f"Processing file: {blob.name}")
        csv_bytes = blob.download_as_bytes()
        csv_text = csv_bytes.decode("utf-8")
        table = build_table_from_csv(csv_text)

        response = dlp_client.deidentify_content(
            request={
                "parent": parent,
                "deidentify_template_name": dlp_template_name,
                "item": {"table": table},
            }
        )

        transformed_table = response.item.table
        output_csv = table_to_csv(transformed_table, [field.name for field in transformed_table.headers])

        raw_blob = raw_bucket.blob(blob.name)
        raw_blob.upload_from_string(output_csv, content_type="text/csv")
        print(f"Wrote transformed file to raw bucket: {raw_bucket_name}/{blob.name}")


if __name__ == "__main__":
    try:
        run_job()
    except Exception as exc:
        print(f"Job failed: {exc}")
        sys.exit(1)
