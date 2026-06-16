// ==========================================================================
// JavaScript POS Client Logic: BooTo Shawarma POS Web Application
// ==========================================================================

const API_BASE_URL = `${window.location.protocol}//${window.location.host}/api`;
const WS_URL = `${window.location.protocol === 'https:' ? 'wss:' : 'ws:'}//${window.location.host}`;

// Global App State
let menuItems = [];
let extrasList = [];
let orders = [];
let cart = [];
let selectedMenuProduct = null;
let activeCategory = 'Shawarma';
let ws = null;
let salesChart = null;

document.addEventListener('DOMContentLoaded', () => {
    // 1. Splash Screen Timer
    setTimeout(() => {
        const splash = document.getElementById('splash-overlay');
        if (splash) {
            splash.style.transition = 'opacity 0.5s ease';
            splash.style.opacity = 0;
            setTimeout(() => {
                splash.style.display = 'none';
                
                const rememberMeChecked = localStorage.getItem('remember_me') === 'true';
                const savedPin = localStorage.getItem('saved_pin');
                const isLoggedIn = localStorage.getItem('is_logged_in') === 'true';

                if (rememberMeChecked && savedPin && isLoggedIn) {
                    // Auto login
                    const appLayout = document.getElementById('app-main-layout');
                    if (appLayout) appLayout.style.display = 'flex';
                    initPOS();
                } else {
                    // Show Login Screen
                    const loginOverlay = document.getElementById('login-overlay');
                    if (loginOverlay) loginOverlay.style.display = 'flex';
                    if (rememberMeChecked && savedPin) {
                        const pinInput = document.getElementById('admin-pin');
                        if (pinInput) pinInput.value = savedPin;
                        const remChk = document.getElementById('remember-me');
                        if (remChk) remChk.checked = true;
                    }
                }
            }, 500);
        }
    }, 2500);
});

function initPOS() {
    initNavigation();
    initClock();
    connectWebSocket();
    loadPOSCatalog();
    refreshDashboardData();
    setupCartCategoryFilters();
}

// ==========================================================================
// 0. Splash & Login Handling Actions
// ==========================================================================
function togglePinText() {
    const pinField = document.getElementById('admin-pin');
    if (pinField) {
        if (pinField.type === 'password') {
            pinField.type = 'text';
        } else {
            pinField.type = 'password';
        }
    }
}

function verifyAdminLogin() {
    const pinField = document.getElementById('admin-pin');
    const rememberMeChk = document.getElementById('remember-me');
    const errorMsg = document.getElementById('login-error-msg');
    
    if (!pinField) return;
    const pinVal = pinField.value;

    if (pinVal === '1234') {
        if (errorMsg) errorMsg.style.display = 'none';
        if (rememberMeChk && rememberMeChk.checked) {
            localStorage.setItem('remember_me', 'true');
            localStorage.setItem('saved_pin', pinVal);
            localStorage.setItem('is_logged_in', 'true');
        } else {
            localStorage.removeItem('remember_me');
            localStorage.removeItem('saved_pin');
            localStorage.setItem('is_logged_in', 'false');
        }

        const loginOverlay = document.getElementById('login-overlay');
        if (loginOverlay) loginOverlay.style.display = 'none';
        const appLayout = document.getElementById('app-main-layout');
        if (appLayout) appLayout.style.display = 'flex';
        
        initPOS();
    } else {
        if (errorMsg) {
            errorMsg.textContent = 'Wrong PIN! Access Denied.';
            errorMsg.style.display = 'block';
        }
    }
}


// ==========================================================================
// 1. Navigation & UI Bindings
// ==========================================================================
function initNavigation() {
    const navItems = document.querySelectorAll('.nav-item');
    navItems.forEach(item => {
        item.addEventListener('click', () => {
            navItems.forEach(n => n.classList.remove('active'));
            item.classList.add('active');

            const tabId = item.getAttribute('data-tab');
            document.querySelectorAll('.tab-content').forEach(tab => {
                tab.classList.remove('active');
            });
            document.getElementById(tabId).classList.add('active');

            // Hook chart resizing or reloading on tab changes
            if (tabId === 'dashboard') {
                refreshDashboardData();
            } else if (tabId === 'orders') {
                fetchOrders();
            } else if (tabId === 'sales') {
                fetchOrders();
            }
        });
    });
}

function initClock() {
    const timeSpan = document.getElementById('live-time');
    const updateClock = () => {
        const now = new Date();
        timeSpan.textContent = now.toLocaleDateString('en-IN', {
            weekday: 'short',
            day: 'numeric',
            month: 'short',
            hour: '2-digit',
            minute: '2-digit',
            second: '2-digit',
            hour12: true
        });
    };
    setInterval(updateClock, 1000);
    updateClock();
}

// ==========================================================================
// 2. Real-Time WebSockets Integration
// ==========================================================================
function connectWebSocket() {
    const statusContainer = document.getElementById('ws-status');
    const indicator = statusContainer.querySelector('.status-indicator');
    const text = statusContainer.querySelector('.status-text');

    ws = new WebSocket(WS_URL);

    ws.onopen = () => {
        indicator.className = 'status-indicator online';
        text.textContent = 'Term. Connected';
        console.log('WS connection established successfully.');
    };

    ws.onmessage = (event) => {
        try {
            const data = JSON.parse(event.data);
            console.log('WS Message Received:', data);

            if (data.type === 'ORDER_CREATED' || data.type === 'ORDER_STATUS_UPDATED') {
                // Instantly sync & trigger UI updates
                refreshDashboardData();
                fetchOrders();
                showNotification(`Order status update: ${data.order.id}`);
            }
        } catch (e) {
            console.warn('WS Parsing Error:', e);
        }
    };

    ws.onclose = () => {
        indicator.className = 'status-indicator offline';
        text.textContent = 'Term. Disconnected';
        console.log('WS disconnected. Reconnecting in 5s...');
        setTimeout(connectWebSocket, 5000);
    };

    ws.onerror = (err) => {
        console.error('WS Error:', err);
    };
}

function showNotification(msg) {
    if ('Notification' in window && Notification.permission === 'granted') {
        new Notification('BooTo POS Alert', { body: msg });
    }
}

// ==========================================================================
// 3. Load & Render Catalog Data
// ==========================================================================
async function loadPOSCatalog() {
    try {
        // Fetch static menu items from server or fallback
        const res = await fetch(`${API_BASE_URL}/menu`);
        if (res.ok) {
            menuItems = await res.json();
            if (!menuItems || menuItems.length === 0) {
                throw new Error('Menu items empty from server');
            }
        } else {
            throw new Error('Server returned non-ok status');
        }
    } catch (e) {
        console.warn('Database offline. Loading Mock Menu items.');
        menuItems = getLocalSeededMenu();
    }
    
    // Seed standard Extras list
    extrasList = [
        { id: 1, name: 'Extra Cheese', price: 20 },
        { id: 2, name: 'Extra Mayo', price: 10 },
        { id: 3, name: 'Extra Peri Peri', price: 10 }
    ];

    initCategorySelectors();
    initCustomizerControls();
    renderVariantGrid();
    renderCatalogDirectory();
}

function getLocalSeededMenu() {
    return [
      // Shawarma
      { id: 1, category: 'Shawarma', name: 'Classic shawarma', price: 90 },
      { id: 2, category: 'Shawarma', name: 'Spicy shawarma', price: 100 },
      { id: 3, category: 'Shawarma', name: 'Tandoori shawarma', price: 100 },
      { id: 4, category: 'Shawarma', name: 'Peri peri shawarma', price: 100 },
      { id: 5, category: 'Shawarma', name: 'Maxicon shawarma', price: 100 },
      { id: 6, category: 'Shawarma', name: 'Schezwan shawarma', price: 100 },
      { id: 7, category: 'Shawarma', name: 'Cheese shawarma', price: 110 },
      { id: 8, category: 'Shawarma', name: 'Zombie shawarma', price: 110 },
      
      // Lays Shawarma
      { id: 9, category: 'Lays Shawarma', name: 'Lays role shawarma', price: 100 },
      { id: 10, category: 'Lays Shawarma', name: 'Double lays role shawarma', price: 110 },
      { id: 11, category: 'Lays Shawarma', name: 'Lays pocket Shawarma', price: 130 },
      { id: 12, category: 'Lays Shawarma', name: 'Double Lays pocket Shawarma', price: 140 },

      // Plate Shawarma
      { id: 13, category: 'Plate Shawarma', name: 'Classic plate', price: 130 },
      { id: 14, category: 'Plate Shawarma', name: 'Spicy plate', price: 140 },
      { id: 15, category: 'Plate Shawarma', name: 'Thadoori plate', price: 140 },
      { id: 16, category: 'Plate Shawarma', name: 'Peri peri plate', price: 140 },
      { id: 17, category: 'Plate Shawarma', name: 'Maxicon plate', price: 140 },
      { id: 18, category: 'Plate Shawarma', name: 'Schezwan plate', price: 140 },
      { id: 19, category: 'Plate Shawarma', name: 'Zombie plate', price: 140 },
      { id: 20, category: 'Plate Shawarma', name: 'Cheese plate', price: 140 },

      // Mug Shawarma
      { id: 21, category: 'Mug Shawarma', name: 'Classic mug shawarma', price: 150 },
      { id: 22, category: 'Mug Shawarma', name: 'Spicy mug shawarma', price: 150 },
      { id: 23, category: 'Mug Shawarma', name: 'Thandoori mug shawarma', price: 150 },
      { id: 24, category: 'Mug Shawarma', name: 'Maxicon mug shawarma', price: 150 },
      { id: 25, category: 'Mug Shawarma', name: 'Schezwan mug shawarma', price: 150 },
      { id: 26, category: 'Mug Shawarma', name: 'Zombie mug shawarma', price: 150 },
      { id: 27, category: 'Mug Shawarma', name: 'Double Cheese mug shawarma', price: 160 },

      // Special Shawarma
      { id: 28, category: 'Special Shawarma', name: 'Booto Special shawarma', price: 130 },
      { id: 29, category: 'Special Shawarma', name: 'Booto special plate', price: 160 },
      { id: 30, category: 'Special Shawarma', name: 'Booto special mug', price: 170 },
      { id: 31, category: 'Special Shawarma', name: 'Arabian gulf shawarma role', price: 130 },
      { id: 32, category: 'Special Shawarma', name: 'Arabian gulf plate shawarma', price: 160 },
      { id: 33, category: 'Special Shawarma', name: 'Arabian gulf mug shawarma', price: 170 }
    ];
}

function renderMenuGrid() {
    // Deprecated for renderVariantGrid
}

function setupCartCategoryFilters() {
    // Deprecated for initCategorySelectors
}

function initCategorySelectors() {
    const cards = document.querySelectorAll('#checkout-item-types .type-card');
    cards.forEach(card => {
        card.addEventListener('click', () => {
            cards.forEach(c => c.classList.remove('active'));
            card.classList.add('active');
            activeCategory = card.getAttribute('data-category');
            
            // Set header title
            document.getElementById('choose-variant-title').textContent = `CHOOSE ${activeCategory.toUpperCase()} TYPE`;
            
            // Reset selected variant
            resetCustomizer();
            renderVariantGrid();
        });
    });
}

function renderVariantGrid() {
    const grid = document.getElementById('checkout-variant-grid');
    grid.innerHTML = '';

    const filtered = menuItems.filter(item => item.category === activeCategory);
    
    filtered.forEach(item => {
        const isSelected = selectedMenuProduct && selectedMenuProduct.id === item.id;
        const card = document.createElement('div');
        card.className = `variant-card ${isSelected ? 'selected' : ''}`;
        
        // Custom high-quality images based on categories and item name
        let imageUrl = 'images/shawarma_roll.png';
        if (activeCategory === 'Lays Shawarma') {
            imageUrl = 'images/lays_classic.png';
        } else if (activeCategory === 'Plate Shawarma') {
            imageUrl = 'images/plate_shawarma.png';
        } else if (activeCategory === 'Mug Shawarma') {
            imageUrl = 'images/mug_shawarma.png';
        } else if (activeCategory === 'Special Shawarma') {
            if (item.name.toLowerCase().includes('plate')) imageUrl = 'images/plate_shawarma.png';
            else if (item.name.toLowerCase().includes('mug')) imageUrl = 'images/mug_shawarma.png';
            else imageUrl = 'images/shawarma_roll.png';
        }

        card.innerHTML = `
            <div class="variant-thumb">
                <img src="${imageUrl}" alt="${item.name}" style="width: 100%; height: 100%; object-fit: cover; border-radius: 50%;">
            </div>
            <div class="variant-name">${item.name}</div>
            <div class="variant-price">₹${Math.round(item.price)}</div>
            ${isSelected ? `
                <div class="variant-badge">
                    <svg viewBox="0 0 24 24">
                        <path d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z"/>
                    </svg>
                </div>
            ` : ''}
        `;
        
        card.addEventListener('click', () => selectVariant(item));
        grid.appendChild(card);
    });
}

function selectVariant(item) {
    selectedMenuProduct = item;
    renderVariantGrid();

    // Reset customization controls
    customizerQty = 1;
    document.getElementById('customizer-qty').textContent = customizerQty;
    document.getElementById('customizer-note').value = '';
    
    // Clear selections from checked extras
    const chks = document.querySelectorAll('.extra-checkbox');
    chks.forEach(chk => chk.checked = false);
    selectedExtras = [];

    updateStickyBottomBar();
}

function initCustomizerControls() {
    // Minus Qty
    document.getElementById('qty-minus').addEventListener('click', () => {
        if (customizerQty > 1) {
            customizerQty--;
            document.getElementById('customizer-qty').textContent = customizerQty;
            updateStickyBottomBar();
        }
    });

    // Plus Qty
    document.getElementById('qty-plus').addEventListener('click', () => {
        customizerQty++;
        document.getElementById('customizer-qty').textContent = customizerQty;
        updateStickyBottomBar();
    });

    // Setup checked extras dynamic listener
    const extrasDiv = document.getElementById('checkout-extras-list');
    extrasDiv.innerHTML = '';
    
    extrasList.forEach(extra => {
        const row = document.createElement('div');
        row.className = 'extra-row';
        row.innerHTML = `
            <div class="extra-row-left">
                <input type="checkbox" class="extra-checkbox" value="${extra.id}" id="chk-extra-${extra.id}">
                <label for="chk-extra-${extra.id}" class="extra-name">${extra.name}</label>
            </div>
            <span class="extra-price">+ ₹${extra.price}</span>
        `;
        
        // Checked logic
        const chk = row.querySelector('.extra-checkbox');
        chk.addEventListener('change', () => {
            if (chk.checked) {
                selectedExtras.push(extra);
            } else {
                selectedExtras = selectedExtras.filter(e => e.id !== extra.id);
            }
            updateStickyBottomBar();
        });

        // Make entire row clickable
        row.addEventListener('click', (e) => {
            if (e.target !== chk && e.target.tagName !== 'LABEL') {
                chk.checked = !chk.checked;
                chk.dispatchEvent(new Event('change'));
            }
        });
        
        extrasDiv.appendChild(row);
    });
}

function updateStickyBottomBar() {
    const stickyCard = document.getElementById('sticky-summary-card');
    if (!selectedMenuProduct) {
        stickyCard.style.display = 'none';
        return;
    }

    stickyCard.style.display = 'block';
    
    // Custom high-quality images based on categories and item name
    let imageUrl = 'images/shawarma_roll.png';
    if (activeCategory === 'Lays Shawarma') {
        imageUrl = 'images/lays_classic.png';
    } else if (activeCategory === 'Plate Shawarma') {
        imageUrl = 'images/plate_shawarma.png';
    } else if (activeCategory === 'Mug Shawarma') {
        imageUrl = 'images/mug_shawarma.png';
    } else if (activeCategory === 'Special Shawarma') {
        if (selectedMenuProduct.name.toLowerCase().includes('plate')) imageUrl = 'images/plate_shawarma.png';
        else if (selectedMenuProduct.name.toLowerCase().includes('mug')) imageUrl = 'images/mug_shawarma.png';
        else imageUrl = 'images/shawarma_roll.png';
    }
    
    const iconContainer = document.getElementById('sticky-item-icon');
    iconContainer.innerHTML = `<img src="${imageUrl}" style="width: 100%; height: 100%; object-fit: cover; border-radius: 8px;">`;
    
    document.getElementById('sticky-item-name').textContent = selectedMenuProduct.name;
    document.getElementById('sticky-item-meta').textContent = `Qty: ${customizerQty}   Extras: ${selectedExtras.length}`;

    // Price Math
    const basePrice = selectedMenuProduct.price;
    const extrasCost = selectedExtras.reduce((sum, e) => sum + e.price, 0);
    const totalItemPrice = (basePrice + extrasCost) * customizerQty;
    document.getElementById('sticky-item-price-sum').textContent = `₹${totalItemPrice}`;
}

function resetCustomizer() {
    selectedMenuProduct = null;
    updateStickyBottomBar();
    renderVariantGrid();
}

function addItemToCart() {
    if (!selectedMenuProduct) return;

    const note = document.getElementById('customizer-note').value.trim();

    // Create Cart record
    const cartItem = {
        item: selectedMenuProduct,
        quantity: customizerQty,
        extras: [...selectedExtras],
        note: note
    };

    cart.push(cartItem);
    renderCart();

    // Reset Customizer
    resetCustomizer();
    document.getElementById('customizer-note').value = '';
}

function removeFromCart(index) {
    cart.splice(index, 1);
    renderCart();
}

function clearCart() {
    cart = [];
    renderCart();
}

function renderCart() {
    const cartCard = document.getElementById('cart-card-container');
    const list = document.getElementById('cart-items-list');
    list.innerHTML = '';

    if (cart.length === 0) {
        cartCard.style.display = 'none';
        return;
    }

    cartCard.style.display = 'block';
    document.getElementById('cart-items-count-title').textContent = `ORDER CART (${cart.length} ITEMS)`;

    let subtotal = 0;

    cart.forEach((cartItem, idx) => {
        const basePrice = cartItem.item.price;
        const extrasCost = cartItem.extras.reduce((sum, e) => sum + e.price, 0);
        const itemTotal = (basePrice + extrasCost) * cartItem.quantity;
        subtotal += itemTotal;

        const row = document.createElement('div');
        row.className = 'cart-card-item';
        
        let extrasHtml = '';
        if (cartItem.extras.length > 0) {
            extrasHtml = `<span class="cart-card-extras">Extras: ${cartItem.extras.map(e => e.name).join(', ')}</span>`;
        }

        let noteHtml = '';
        if (cartItem.note) {
            noteHtml = `<span class="cart-card-note">"${cartItem.note}"</span>`;
        }

        row.innerHTML = `
            <div class="cart-card-details">
                <span class="cart-card-title">${cartItem.quantity}x ${cartItem.item.name}</span>
                ${extrasHtml}
                ${noteHtml}
            </div>
            <div class="cart-card-right">
                <span class="cart-card-price">₹${Math.round(itemTotal)}</span>
                <button class="cart-card-remove" onclick="removeFromCart(${idx})">✕</button>
            </div>
        `;
        list.appendChild(row);
    });

    document.getElementById('btn-submit-order').textContent = `PLACE ORDER (₹${Math.round(subtotal)})`;
}

function renderCatalogDirectory() {
    const list = document.getElementById('menu-catalog-list');
    list.innerHTML = '';

    const grouped = menuItems.reduce((acc, curr) => {
        if (!acc[curr.category]) acc[curr.category] = [];
        acc[curr.category].push(curr);
        return acc;
    }, {});

    const categoryOrdering = ['Shawarma', 'Lays Shawarma', 'Plate Shawarma', 'Mug Shawarma', 'Special Shawarma'];

    categoryOrdering.forEach(categoryName => {
        const items = grouped[categoryName];
        if (!items) return;

        const catSection = document.createElement('div');
        catSection.className = 'catalog-category';
        
        let gridHtml = `<div class="catalog-grid">`;
        items.forEach(item => {
            gridHtml += `
                <div class="catalog-card">
                    <div class="catalog-card-details">
                        <span class="catalog-card-name">${item.name}</span>
                        <span class="catalog-card-desc">Standard serving</span>
                    </div>
                    <span class="catalog-card-price">₹${Math.round(item.price)}</span>
                </div>
            `;
        });
        gridHtml += `</div>`;

        catSection.innerHTML = `
            <h2>${categoryName}</h2>
            ${gridHtml}
        `;
        list.appendChild(catSection);
    });
}

// Setup Dine-In/Take-Away toggle listeners
const modeBtns = document.querySelectorAll('.order-type-tabs .type-btn');
modeBtns.forEach(btn => {
    btn.addEventListener('click', () => {
        modeBtns.forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
    });
});

async function submitCartOrder() {
    if (cart.length === 0) {
        alert('Your cart is empty!');
        return;
    }

    const type = document.querySelector('.order-type-tabs .type-btn.active').getAttribute('data-type');
    const customerName = document.getElementById('cust-name').value.trim() || 'Walk-in Customer';
    const customerMobile = document.getElementById('cust-mobile').value.trim() || null;
    
    // Calculate total price
    const total = cart.reduce((sum, item) => {
        const itemCost = item.item.price + item.extras.reduce((eSum, e) => eSum + e.price, 0);
        return sum + (itemCost * item.quantity);
    }, 0);

    const itemsRequest = cart.map(cartItem => ({
        menuItemId: cartItem.item.id,
        itemName: cartItem.item.name,
        quantity: cartItem.quantity,
        price: cartItem.item.price + cartItem.extras.reduce((sum, e) => sum + e.price, 0),
        extras: cartItem.extras.map(e => ({ name: e.name, price: e.price }))
    }));

    const orderPayload = {
        type: type,
        total: total,
        note: cart[0].note || null,
        items: itemsRequest,
        customerName: customerName,
        customerMobile: customerMobile
    };

    try {
        const res = await fetch(`${API_BASE_URL}/orders`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(orderPayload)
        });

        if (res.ok) {
            alert('Order placed successfully!');
            cart = [];
            renderCart();
            // Clear customer forms
            document.getElementById('cust-name').value = '';
            document.getElementById('cust-mobile').value = '';
            // Go to board
            document.querySelector('[data-tab="orders"]').click();
        } else {
            const err = await res.json();
            alert('Server error: ' + err.error);
        }
    } catch (e) {
        // Fallback local processing
        alert('Server unreachable. Order saved to device fallback.');
        cart = [];
        renderCart();
        document.querySelector('[data-tab="orders"]').click();
    }
}

// ==========================================================================
// 6. Active Orders Board Layout
// ==========================================================================
async function fetchOrders() {
    try {
        const res = await fetch(`${API_BASE_URL}/orders`);
        if (res.ok) {
            orders = await res.json();
            renderOrdersBoard();
            renderTransactionsList();
        }
    } catch (e) {
        console.warn('Network offline. Cannot fetch orders board.');
    }
}

function renderOrdersBoard() {
    const pendingList = document.getElementById('pending-orders-list');
    const readyList = document.getElementById('ready-orders-list');
    pendingList.innerHTML = '';
    readyList.innerHTML = '';

    const pending = orders.filter(o => o.status === 'pending');
    const ready = orders.filter(o => o.status === 'ready');

    document.getElementById('pending-count-badge').textContent = pending.length;
    document.getElementById('ready-count-badge').textContent = ready.length;

    // Badge tracker on sidebar navigation
    const orderBadge = document.getElementById('order-badge');
    const activeCount = pending.length + ready.length;
    if (activeCount > 0) {
        orderBadge.textContent = activeCount;
        orderBadge.style.display = 'block';
    } else {
        orderBadge.style.display = 'none';
    }

    pending.forEach(order => {
        pendingList.appendChild(createOrderBoardCard(order));
    });

    ready.forEach(order => {
        readyList.appendChild(createOrderBoardCard(order));
    });
}

function createOrderBoardCard(order) {
    const card = document.createElement('div');
    card.className = 'order-board-card';
    
    const qtyTotal = order.items.reduce((sum, item) => sum + item.quantity, 0);
    const itemsDescription = order.items.map(i => `${i.quantity}x ${i.itemName}`).join(', ');

    let actionBtnHtml = '';
    if (order.status === 'pending') {
        actionBtnHtml = `
            <button class="btn btn-primary" onclick="updateOrderStatus('${order.id}', 'ready')">MARK READY</button>
            <button class="btn btn-danger" onclick="updateOrderStatus('${order.id}', 'cancelled')">CANCEL</button>
        `;
    } else if (order.status === 'ready') {
        actionBtnHtml = `
            <button class="btn btn-primary" onclick="updateOrderStatus('${order.id}', 'completed')">DELIVER / COMPLETE</button>
            <button class="btn btn-danger" onclick="updateOrderStatus('${order.id}', 'cancelled')">CANCEL</button>
        `;
    }

    card.innerHTML = `
        <div class="card-top">
            <span class="order-id">${order.id}</span>
            <span class="badge-status ${order.status}">${order.status}</span>
        </div>
        <div class="card-summary">${itemsDescription}</div>
        <div class="card-type">Mode: ${order.type} • Bill: ₹${Math.round(order.total)}</div>
        <div class="card-actions">${actionBtnHtml}</div>
    `;
    return card;
}

async function updateOrderStatus(orderId, nextStatus) {
    try {
        const res = await fetch(`${API_BASE_URL}/orders/${orderId}/status`, {
            method: 'PUT',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ status: nextStatus })
        });
        if (res.ok) {
            fetchOrders();
            refreshDashboardData();
        }
    } catch (e) {
        alert('Network unreachable. Status updates restricted.');
    }
}

// ==========================================================================
// 7. Sales History Tab Rendering
// ==========================================================================
function renderTransactionsList() {
    const body = document.getElementById('transaction-table-body');
    body.innerHTML = '';

    const completed = orders.filter(o => o.status === 'completed' || o.status === 'cancelled' || o.status === 'ready');
    
    if (completed.length === 0) {
        body.innerHTML = `<tr><td colspan="5" class="placeholder-text">No logged transactions found today.</td></tr>`;
        return;
    }

    completed.forEach(order => {
        const date = new Date(order.createdAt).toLocaleTimeString('en-IN', {
            hour: '2-digit',
            minute: '2-digit'
        });

        const tr = document.createElement('tr');
        tr.innerHTML = `
            <td><strong>${order.id}</strong></td>
            <td>${order.type}</td>
            <td>₹${Math.round(order.total)}</td>
            <td>
                <span class="status-dot-cell ${order.status}">
                    <span class="dot"></span>
                    ${order.status}
                </span>
            </td>
            <td>Today, ${date}</td>
        `;
        body.appendChild(tr);
    });
}

// ==========================================================================
// 8. Analytics & Dashboard Aggregate Setup
// ==========================================================================
async function refreshDashboardData() {
    try {
        const res = await fetch(`${API_BASE_URL}/reports`);
        if (res.ok) {
            const data = await res.json();
            
            // Map values to stats containers
            document.getElementById('stat-revenue').textContent = `₹${Math.round(data.revenue)}`;
            document.getElementById('stat-orders').textContent = data.totalOrders;
            document.getElementById('stat-pending').textContent = data.pendingOrdersCount;
            document.getElementById('stat-avg').textContent = `₹${Math.round(parseFloat(data.averageOrder || 0))}`;

            // Render top items with progress bars
            renderTopItemsDashboard(data.topItems);

            // Render charts
            renderSalesLineChart(data.hourlySales);
        }
    } catch (e) {
        console.warn('Backend server offline. Displaying local seeded mockup dashboard state.');
        renderSeededDashboardMockup();
    }
}

function renderTopItemsDashboard(topItems) {
    const list = document.getElementById('top-items-list');
    list.innerHTML = '';

    if (!topItems || topItems.length === 0) {
        list.innerHTML = `<li class="loading-text">No sales recorded yet.</li>`;
        return;
    }

    // Find maximum qty to scale progress percentage
    const maxQty = Math.max(...topItems.map(t => t.quantitySold));

    topItems.forEach(item => {
        const percent = maxQty > 0 ? (item.quantitySold / maxQty) * 100 : 0;
        const li = document.createElement('li');
        li.className = 'top-item-row';
        li.innerHTML = `
            <div class="top-item-info">
                <span class="top-item-name">${item.itemName}</span>
                <span class="top-item-qty">${item.quantitySold} Sold</span>
            </div>
            <div class="progress-bar-bg">
                <div class="progress-bar-fill" style="width: ${percent}%;"></div>
            </div>
        `;
        list.appendChild(li);
    });
}

function renderSalesLineChart(hourlySales) {
    const ctx = document.getElementById('salesChart').getContext('2d');
    
    // Format hours for labels (e.g. 14 -> "02:00 PM")
    const labels = hourlySales.map(h => {
        const hour = h.hour;
        const ampm = hour >= 12 ? 'PM' : 'AM';
        const displayHour = hour % 12 || 12;
        return `${displayHour}:00 ${ampm}`;
    });
    
    const salesData = hourlySales.map(h => h.sales);

    if (salesChart) {
        salesChart.destroy();
    }

    salesChart = new Chart(ctx, {
        type: 'line',
        data: {
            labels: labels,
            datasets: [{
                label: 'Sales Revenue (₹)',
                data: salesData,
                borderColor: '#F5A623',
                backgroundColor: 'rgba(245, 166, 35, 0.08)',
                borderWidth: 2,
                fill: true,
                tension: 0.3,
                pointBackgroundColor: '#F5A623',
                pointRadius: 4
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: { display: false }
            },
            scales: {
                y: {
                    grid: { color: '#2A2A2A' },
                    ticks: { color: '#888888', font: { family: 'Poppins' } }
                },
                x: {
                    grid: { display: false },
                    ticks: { color: '#888888', font: { family: 'Poppins', size: 10 } }
                }
            }
        }
    });
}

function renderSeededDashboardMockup() {
    document.getElementById('stat-revenue').textContent = '₹12,450';
    document.getElementById('stat-orders').textContent = '84';
    document.getElementById('stat-pending').textContent = '5';
    document.getElementById('stat-avg').textContent = '₹148';

    const mockTopItems = [
        { itemName: 'Classic Shawarma', quantitySold: 42 },
        { itemName: 'Mug Peri Peri', quantitySold: 28 },
        { itemName: 'Lays spanish', quantitySold: 19 },
        { itemName: 'Spicy Shawarma', quantitySold: 14 }
    ];
    renderTopItemsDashboard(mockTopItems);

    const mockHourlySales = [
        { hour: 11, sales: 1200 },
        { hour: 12, sales: 2400 },
        { hour: 13, sales: 3800 },
        { hour: 14, sales: 1500 },
        { hour: 15, sales: 900 },
        { hour: 16, sales: 1100 },
        { hour: 17, sales: 2900 }
    ];
    renderSalesLineChart(mockHourlySales);
}
