const url = 'https://mca-boot-camp-1.onrender.com/api/menu';
const maxAttempts = 30;
const intervalMs = 10000; // 10 seconds

async function check() {
  for (let i = 1; i <= maxAttempts; i++) {
    try {
      const res = await fetch(url);
      console.log(`[Attempt ${i}/${maxAttempts}] Status: ${res.status}`);
      if (res.status === 200) {
        const data = await res.json();
        console.log('🎉 LIVE VERIFICATION SUCCESSFUL!');
        console.log(`Successfully fetched ${data.length} menu items from the remote database!`);
        process.exit(0);
      } else {
        const text = await res.text();
        console.log('Error Response:', text);
      }
    } catch (err) {
      console.log(`[Attempt ${i}/${maxAttempts}] Fetch failed: ${err.message}`);
    }
    await new Promise(resolve => setTimeout(resolve, intervalMs));
  }
  console.log('❌ Timeout waiting for live deployment.');
  process.exit(1);
}

check();
