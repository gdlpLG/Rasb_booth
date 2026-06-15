/* ===== Pibooth Web Controller ===== */

const socket = io();
let currentLbFile = null;
let latestFilename = null;
let statusCheckInterval = null;
let isWorking = false;

// ===== Socket IO =====
socket.on('connect', () => {
    document.getElementById('statusDot').classList.add('on');
    loadLatestPhoto();
    startStatusMonitoring();
});
socket.on('disconnect', () => {
    document.getElementById('statusDot').classList.remove('on');
    stopStatusMonitoring();
});
socket.on('new_picture', (data) => {
    // Refresh only when a new picture is actually ready
    loadLatestPhoto();
    hideWorkingOverlay();
});

// ===== Init =====
document.addEventListener('DOMContentLoaded', () => {
    loadLatestPhoto();
    startStatusMonitoring();
});

// ===== Pages =====
function showPage(id) {
    document.querySelectorAll('.page').forEach(p => p.classList.remove('active'));
    document.getElementById('page-' + id).classList.add('active');
    if (id === 'gallery') loadGallery();
    if (id === 'home') loadLatestPhoto();
    if (id === 'logs') refreshLogs();
}

// ===== Logs =====
function refreshLogs() {
    const el = document.getElementById('logContent');
    el.textContent = 'Chargement des logs...';
    fetch('/api/logs?lines=100')
        .then(r => r.text())
        .then(text => {
            el.textContent = text;
            // Scroll to bottom
            el.scrollTop = el.scrollHeight;
        })
        .catch(err => {
            el.textContent = 'Erreur lors du chargement des logs : ' + err;
        });
    
    // Also refresh system info
    refreshSystemInfo();
}

function refreshSystemInfo() {
    fetch('/api/system/info')
        .then(r => r.json())
        .then(data => {
            if (data.cpu_temp !== null) {
                document.getElementById('sysTemp').textContent = data.cpu_temp + '°C';
            }
            document.getElementById('sysDisk').textContent = data.disk_free_gb + ' Go libres (' + (100 - data.disk_used_percent).toFixed(1) + '%)';
            document.getElementById('sysUptime').textContent = data.uptime;
        })
        .catch(() => {});
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
                    // Pibooth: LEFT = 4 photos, RIGHT = 1 photo
                    const direction = (count === 1) ? 'right' : 'left';
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

// ===== Working Overlay =====
function showWorkingOverlay(text = '📸 Capture en cours...', subtext = 'Veuillez patienter') {
    isWorking = true;
    const overlay = document.getElementById('workingOverlay');
    document.getElementById('workingText').textContent = text;
    document.getElementById('workingSubtext').textContent = subtext;
    overlay.classList.add('active');
    
    // Désactiver tous les boutons de capture et navigation
    document.querySelectorAll('.cap-btn, .nav-btn').forEach(btn => {
        btn.disabled = true;
    });
}

function hideWorkingOverlay() {
    isWorking = false;
    document.getElementById('workingOverlay').classList.remove('active');
    
    // Réactiver tous les boutons
    document.querySelectorAll('.cap-btn, .nav-btn').forEach(btn => {
        btn.disabled = false;
    });
}

// ===== Status Monitoring =====
function startStatusMonitoring() {
    if (statusCheckInterval) return;
    
    // Vérifier l'état toutes les 500ms
    statusCheckInterval = setInterval(() => {
        fetch('/api/status')
            .then(r => r.json())
            .then(data => {
                const state = data.state;
                const cameraConnected = data.camera_connected;
                
                // Update camera indicator
                updateCameraIndicator(cameraConnected);
                
                // États qui indiquent que Pibooth travaille
                const workingStates = ['choose', 'chosen', 'preview', 'capture', 'processing'];
                
                if (workingStates.includes(state) && !isWorking) {
                    // Pibooth a commencé à travailler
                    let text = '📸 Capture en cours...';
                    let subtext = 'Veuillez patienter';
                    
                    if (state === 'choose' || state === 'chosen') {
                        text = '📋 Sélection en cours...';
                        subtext = 'Choix de la mise en page';
                    } else if (state === 'preview') {
                        text = '👀 Prévisualisation...';
                        subtext = 'Préparez-vous !';
                    } else if (state === 'capture') {
                        text = '📸 Capture !';
                        subtext = 'Souriez !';
                    } else if (state === 'processing') {
                        text = '🎨 Création de la photo...';
                        subtext = 'Traitement en cours';
                    }
                    
                    showWorkingOverlay(text, subtext);
                } else if (state === 'wait' && isWorking) {
                    // Pibooth a terminé
                    hideWorkingOverlay();
                }
                
                // Disable capture buttons if camera is disconnected
                if (!cameraConnected && !isWorking) {
                    document.querySelectorAll('.cap-btn').forEach(btn => {
                        btn.disabled = true;
                    });
                } else if (cameraConnected && !isWorking) {
                    document.querySelectorAll('.cap-btn').forEach(btn => {
                        btn.disabled = false;
                    });
                }
            })
            .catch(() => {
                // En cas d'erreur de connexion, afficher la caméra comme déconnectée
                updateCameraIndicator(false);
            });
    }, 500);
}

function stopStatusMonitoring() {
    if (statusCheckInterval) {
        clearInterval(statusCheckInterval);
        statusCheckInterval = null;
    }
    hideWorkingOverlay();
}

// ===== Camera Indicator =====
let lastCameraState = null;

function updateCameraIndicator(connected) {
    const indicator = document.getElementById('cameraIndicator');
    
    // Only update if state changed
    if (connected === lastCameraState) return;
    lastCameraState = connected;
    
    // Remove all state classes
    indicator.classList.remove('connected', 'disconnected');
    
    if (connected) {
        indicator.classList.add('connected');
        indicator.title = 'Caméra connectée ✓';
        
        // Show toast only when reconnecting (not on initial load)
        if (lastCameraState === false) {
            toast('📷 Caméra reconnectée !');
        }
    } else {
        indicator.classList.add('disconnected');
        indicator.title = 'Caméra déconnectée ⚠️';
        toast('⚠️ Caméra déconnectée - Veuillez la reconnecter');
    }
}
