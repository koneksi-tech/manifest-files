#!/bin/bash
# Setup script to configure MinIO Object Lock where only user 'keen' can delete objects
# All other users are restricted by the 30-day governance retention policy

set -e

# Configuration variables
MINIO_ALIAS="minio-local"
MINIO_ENDPOINT="http://localhost:9000"  # Change this to your MinIO endpoint
MINIO_ADMIN_USER="minioadmin"          # Change this to your admin username
MINIO_ADMIN_PASS="minioadmin"          # Change this to your admin password
BUCKET_NAME="secure-bucket"            # Change this to your bucket name
KEEN_PASSWORD="keen-secure-password"   # Set a secure password for keen
REGULAR_PASSWORD="regular-user-pass"   # Set password for regular users

echo "🔒 Setting up MinIO Object Lock with keen-only delete permissions..."

# Step 1: Configure MinIO client
echo "📡 Configuring MinIO client..."
mc alias set $MINIO_ALIAS $MINIO_ENDPOINT $MINIO_ADMIN_USER $MINIO_ADMIN_PASS

# Step 2: Create policy for regular users (no delete permissions)
echo "📋 Creating policy for regular users (no delete permissions)..."
cat > /tmp/regular-user-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket",
        "s3:GetObjectVersion",
        "s3:ListBucketVersions",
        "s3:GetObjectRetention",
        "s3:GetObjectLegalHold"
      ],
      "Resource": [
        "arn:aws:s3:::BUCKET_NAME",
        "arn:aws:s3:::BUCKET_NAME/*"
      ]
    },
    {
      "Effect": "Deny",
      "Action": [
        "s3:DeleteObject",
        "s3:DeleteObjectVersion",
        "s3:BypassGovernanceRetention",
        "s3:PutObjectRetention",
        "s3:PutObjectLegalHold"
      ],
      "Resource": [
        "arn:aws:s3:::BUCKET_NAME/*"
      ]
    }
  ]
}
EOF

# Replace placeholder with actual bucket name
sed -i "s/BUCKET_NAME/$BUCKET_NAME/g" /tmp/regular-user-policy.json

# Step 3: Create policy for user 'keen' (full delete permissions)
echo "🔑 Creating policy for user 'keen' (full delete permissions)..."
cat > /tmp/keen-admin-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:DeleteObjectVersion",
        "s3:ListBucket",
        "s3:GetObjectVersion",
        "s3:ListBucketVersions",
        "s3:BypassGovernanceRetention",
        "s3:GetObjectRetention",
        "s3:PutObjectRetention",
        "s3:GetObjectLegalHold",
        "s3:PutObjectLegalHold"
      ],
      "Resource": [
        "arn:aws:s3:::BUCKET_NAME",
        "arn:aws:s3:::BUCKET_NAME/*"
      ]
    }
  ]
}
EOF

# Replace placeholder with actual bucket name
sed -i "s/BUCKET_NAME/$BUCKET_NAME/g" /tmp/keen-admin-policy.json

# Step 4: Add policies to MinIO
echo "📝 Adding policies to MinIO..."
mc admin policy create $MINIO_ALIAS regular-user-policy /tmp/regular-user-policy.json
mc admin policy create $MINIO_ALIAS keen-admin-policy /tmp/keen-admin-policy.json

# Step 5: Create users
echo "👤 Creating users..."
mc admin user add $MINIO_ALIAS keen $KEEN_PASSWORD
mc admin user add $MINIO_ALIAS regularuser $REGULAR_PASSWORD

# Step 6: Assign policies to users
echo "🔗 Assigning policies to users..."
mc admin policy attach $MINIO_ALIAS keen-admin-policy --user keen
mc admin policy attach $MINIO_ALIAS regular-user-policy --user regularuser

# Step 7: Create bucket with Object Lock (if it doesn't exist)
echo "🪣 Creating bucket with Object Lock enabled..."
if ! mc ls $MINIO_ALIAS/$BUCKET_NAME > /dev/null 2>&1; then
    mc mb --with-lock $MINIO_ALIAS/$BUCKET_NAME
    echo "✅ Bucket '$BUCKET_NAME' created with Object Lock enabled"
else
    echo "⚠️  Bucket '$BUCKET_NAME' already exists"
    echo "   Note: Object Lock cannot be enabled on existing buckets"
    echo "   You may need to create a new bucket or migrate data"
fi

# Step 8: Set default retention policy (30 days governance mode)
echo "⏰ Setting default retention policy (30 days governance mode)..."
mc retention set --default governance 30d $MINIO_ALIAS/$BUCKET_NAME

# Step 9: Verify configuration
echo "🔍 Verifying configuration..."
echo ""
echo "Policies created:"
mc admin policy list $MINIO_ALIAS | grep -E "(keen-admin-policy|regular-user-policy)"

echo ""
echo "Users created:"
mc admin user list $MINIO_ALIAS | grep -E "(keen|regularuser)"

echo ""
echo "Bucket retention policy:"
mc retention info $MINIO_ALIAS/$BUCKET_NAME

echo ""
echo "✅ Setup completed successfully!"
echo ""
echo "🔒 Object Lock Configuration Summary:"
echo "  • Bucket: $BUCKET_NAME"
echo "  • Retention: 30 days (Governance mode)"
echo "  • User 'keen': CAN delete objects (has BypassGovernanceRetention)"
echo "  • Other users: CANNOT delete objects during retention period"
echo ""
echo "🧪 Testing Instructions:"
echo "1. Test with user 'keen':"
echo "   mc alias set keen-alias $MINIO_ENDPOINT keen $KEEN_PASSWORD"
echo "   mc cp somefile keen-alias/$BUCKET_NAME/"
echo "   mc rm keen-alias/$BUCKET_NAME/somefile  # Should work"
echo ""
echo "2. Test with regular user:"
echo "   mc alias set regular-alias $MINIO_ENDPOINT regularuser $REGULAR_PASSWORD"
echo "   mc cp somefile regular-alias/$BUCKET_NAME/"
echo "   mc rm regular-alias/$BUCKET_NAME/somefile  # Should be denied"
echo ""

# Cleanup temporary files
rm -f /tmp/regular-user-policy.json /tmp/keen-admin-policy.json

echo "🎉 Object Lock is now configured! Only user 'keen' can delete objects." 