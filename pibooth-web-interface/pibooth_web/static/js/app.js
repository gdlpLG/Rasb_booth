/* ===== Pibooth Web Controller ===== */

const socket = io();
let currentLbFile = null;
let latestFilename = null;

// ===== Socket IO =====
socket.on('connect', () => {
    document.getElementById('statusDot').classList.add('on');
    loadLatestPhoto();
});
socket.on('disconnect', () => {
    document.getElementById('statusDot').classList.remove('on');
});
socket.on('new_picture', (data) => {
    // Refresh only when a new picture is actually ready
    loadLatestPhoto();
});

// ===== Init =====
document.addEventListener('DOMContentLoaded', loadLatestPhoto);

// ===== Pages =====
function showPage(id) {
    document.querySelectorAll('.page').forEach(p => p.classList.remove('active'));
    document.getElementById('page-' + id).classList.add('active');
    if (id === 'gallery') loadGallery();
    if (id === 'home') loadLatestPhoto();
}

// ===== Dernière photo =====
function loadLatestPhoto() {
    fetch('/api/pictures/gallery')
        .then(r => r.json())
        .then(data => {
            if (data.pictures && data.pictures.length > 0) {
                const newest = data.pictures[0]; // already sorted newest first
                latestFilename = newest.filename;
                const img = document.getElementById('lastPhoto');
                const ph = document.getElementById('lastPhotoPlaceholder');
                img.src = '/api/pictures/file/' + newest.filename + '?t=' + Date.now();
                img.style.display = 'block';
                ph.style.display = 'none';
            }
        })
        .catch(() => {});
}

function openLightboxFromLatest() {
    if (latestFilename) openLightbox(latestFilename);
}

// ===== Capture =====
function doCapture(count, useTimer) {
    if (useTimer) {
        showPage('timer');
        startTimer(10, () => {
            triggerCapture(count, true);
        });
    } else {
        triggerCapture(count, false);
    }
}

function triggerCapture(count, useTimer) {
    const body = JSON.stringify({ use_timer: useTimer || false });
    fetch('/api/action/capture', { 
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: body
    })
        .then(r => r.json())
        .then(d => {
            showPage('home');
            if (d.success) {
                toast('📸 Capture lancée !');
                
                // Automatically send the choice after Pibooth enters choice mode
                // Wait 200ms for Pibooth to be ready
                setTimeout(() => {
                    const direction = (count === 1) ? 'left' : 'right';
                    fetch(`/api/action/choose/${direction}`, { method: 'POST' })
                        .then(r => r.json())
                        .catch(err => console.warn('Choice error:', err));
                }, 200);
                
                // Photo will be refreshed automatically via SocketIO 'new_picture' event
            } else {
                toast('❌ ' + (d.message || 'Erreur'));
            }
        })
        .catch(() => {
            showPage('home');
            toast('❌ Connexion perdue');
        });
}

// ===== Timer =====
let timerInterval = null;
function startTimer(seconds, callback) {
    let remaining = seconds;
    const el = document.getElementById('timerCount');
    el.textContent = remaining;
    if (timerInterval) clearInterval(timerInterval);
    timerInterval = setInterval(() => {
        remaining--;
        el.textContent = remaining;
        if (remaining <= 0) {
            clearInterval(timerInterval);
            timerInterval = null;
            callback();
        }
    }, 1000);
}

// ===== Galerie =====
function loadGallery() {
    const list = document.getElementById('galList');
    list.innerHTML = '<p class="gal-empty">Chargement…</p>';
    fetch('/api/pictures/gallery')
        .then(r => r.json())
        .then(data => {
            if (!data.pictures || data.pictures.length === 0) {
                list.innerHTML = '<p class="gal-empty">Aucune photo</p>';
                return;
            }
            list.innerHTML = '';
            data.pictures.forEach(pic => {
                const img = document.createElement('img');
                img.className = 'gal-thumb';
                img.src = '/api/pictures/file/' + pic.filename;
                img.loading = 'lazy';
                img.onclick = () => openLightbox(pic.filename);
                list.appendChild(img);
            });
        })
        .catch(() => {
            list.innerHTML = '<p class="gal-empty">Erreur de chargement</p>';
        });
}

// ===== Lightbox =====
function openLightbox(filename) {
    currentLbFile = filename;
    document.getElementById('lbImg').src = '/api/pictures/file/' + filename;
    document.getElementById('lbMsg').textContent = '';
    document.getElementById('lightbox').classList.add('open');
}

function closeLightbox(e) {
    if (e && e.target && !e.target.classList.contains('lightbox')) return;
    document.getElementById('lightbox').classList.remove('open');
    currentLbFile = null;
}

// ===== Impression =====
function printPhoto() {
    if (!currentLbFile) return;
    const msg = document.getElementById('lbMsg');
    msg.textContent = '⏳ Envoi…';
    fetch('/api/pictures/print/' + currentLbFile, { method: 'POST' })
        .then(r => r.json())
        .then(d => {
            if (d.success) {
                msg.textContent = '✅ Impression envoyée !';
                toast('🖨️ Impression OK');
            } else {
                msg.textContent = '❌ ' + (d.error || 'Erreur');
            }
        })
        .catch(() => { msg.textContent = '❌ Connexion perdue'; });
}

// ===== Toast =====
function toast(text) {
    const t = document.getElementById('toast');
    t.textContent = text;
    t.classList.add('show');
    setTimeout(() => t.classList.remove('show'), 3000);
}