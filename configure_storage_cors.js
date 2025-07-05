const { Storage } = require('@google-cloud/storage');

async function configureCORS() {
  const storage = new Storage();
  const bucketName = process.env.FIREBASE_STORAGE_BUCKET;
  
  if (!bucketName) {
    console.error('Please set FIREBASE_STORAGE_BUCKET environment variable');
    process.exit(1);
  }
  
  const corsConfiguration = [
    {
      origin: ['*'],
      method: ['GET', 'POST', 'PUT', 'DELETE'],
      responseHeader: ['Content-Type', 'Authorization'],
      maxAgeSeconds: 3600,
    },
  ];

  await storage.bucket(bucketName).setCorsConfiguration(corsConfiguration);
  console.log('✅ CORS configuration set for Storage bucket');
}

configureCORS().catch(console.error);
