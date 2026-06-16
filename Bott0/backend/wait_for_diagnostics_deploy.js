const url = 'https://mca-boot-camp-1.onrender.com/api/menu';
const maxAttempts = 30;
const intervalMs = 10000; // 10 seconds

async function check() {
  for (let i = 1; i <= maxAttempts; i++) {
    try {
      const res = await fetch(url);
      const data = await res.json();
      console.log(`[Attempt ${i}/${maxAttempts}] Status: ${res.status}`);
      if (data && data.details) {
        console.log('🎉 DIAGNOSTIC DEPLOYMENT LIVE!');
        console.log('Error Details:', data.details);
        console.log('Error Stack:', data.stack);
        process.exit(0);
      } else {
        console.log('Response (no details yet):', data);
      }
    } catch (err) {
      console.log(`[Attempt ${i}/${maxAttempts}] Fetch failed: ${err.message}`);
    }
    await new Promise(resolve => setTimeout(resolve, intervalMs));
  }
  console.log('❌ Timeout waiting for diagnostic deployment.');
  process.exit(1);
}

check();
