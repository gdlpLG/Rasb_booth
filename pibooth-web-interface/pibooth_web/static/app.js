/* Pibooth Web Interface – Client JavaScript */

const POLL_INTERVAL = 1500; // ms

// -----------------------------------------------------------------------
// Tab navigation
// -----------------------------------------------------------------------

function showTab(tabName) {
    // Hide all tab contents
    document.querySelectorAll('.tab-content').forEach(el => {
        el.classList.remove('active');
    });
    // Deactivate all tab buttons
    document.querySelectorAll('.tab').forEach(el => {
        el.classList.remove('active');
    });

    // Show selected tab
    const tabEl = document.getElementById('tab-' + tabName);
    if (tabEl) tabEl.classList.add('active');

    // Activate the clicked tab button
    const tabs = document.querySelectorAll('.tab');
    tabs.forEach(t => {
        if (t.textContent.toLowerCase().includes(tabName === 'control' ? 'contrôle' : 'galerie')) {
            t.classList.add('active');
        }
    });

    // Load gallery when switching to gallery tab
    if (tabName === 'gallery') {
        loadGallery();
    }
}

// -----------------------------------------------------------------------
// Actions
// -----------------------------------------------------------------------

/**
 * Send a POST action to the API.
 * @param {string} action - action path (e.g. "capture", "print", "choose/left")
 */
function doAction(action) {
    // Show feedback
    showStatus('Envoi: ' + action + '...', 'info');

    fetch('/api/action/' + action, { method: 'POST' })
        .then(r => r.json())
        .then(data => {
            console.log('Action response:', data);
            if (data.success) {
                showStatus('✅ ' + action + ' envoyé !', 'success');
            } else {
                showStatus('⚠️ Pibooth pas prêt', 'warning');
            }
            // Immediately refresh status
            refreshStatus();
        })
        .catch(err => {
            console.error('Action error:', err);
            showStatus('❌ Erreur: ' + err.message, 'error');
        });
}

// -----------------------------------------------------------------------
// Status message
// -----------------------------------------------------------------------

let statusTimeout = null;

function showStatus(message, type) {
    const el = document.getElementById('status-message');
    if (!el) return;
    el.textContent = message;
    el.className = 'status-message status-' + (type || 'info');
    el.style.display = 'block';

    if (statusTimeout) clearTimeout(statusTimeout);
    statusTimeout = setTimeout(() => {
        el.style.display = 'none';
    }, 3000);
}

// -----------------------------------------------------------------------
// Status polling
// -----------------------------------------------------------------------

const STATE_LABELS = {
    'wait': '⏳ En attente',
    'choose': '🔀 Choix du mode',
    'chosen': '✅ Mode choisi',
    'preview': '👁️ Aperçu',
    'capture': '📸 Capture en cours',
    'processing': '⚙️ Traitement',
    'print': '🖨️ Impression',
    'finish': '🎉 Terminé',
    'failsafe': '⚠️ Erreur'
};

/**
 * Poll the status API and update the UI.
 */
function refreshStatus() {
    fetch('/api/status')
        .then(r => r.json())
        .then(data => {
            // Update state display
            const stateEl = document.getElementById('state');
            stateEl.textContent = STATE_LABELS[data.state] || data.state || '…';

            // Update counters
            document.getElementById('count-taken').textContent = data.count_taken || 0;
            document.getElementById('count-printed').textContent = data.count_printed || 0;

            // Show/hide choice buttons depending on state
            const choicesSection = document.getElementById('choices');
            const actionsSection = document.getElementById('actions');
            if (data.state === 'choose') {
                choicesSection.style.display = 'flex';
                actionsSection.style.display = 'none';
            } else {
                choicesSection.style.display = 'none';
                actionsSection.style.display = 'flex';
            }

            // Disable buttons during active processing
            const btnCapture = document.getElementById('btn-capture');
            const btnPrint = document.getElementById('btn-print');
            const busyStates = ['preview', 'capture', 'processing', 'chosen'];
            const isBusy = busyStates.includes(data.state);
            btnCapture.disabled = isBusy;
            btnPrint.disabled = (data.state !== 'print' && data.state !== 'wait');

            // Update latest picture
            if (data.has_picture) {
                const img = document.getElementById('latest-picture');
                const noImg = document.getElementById('no-picture');
                const expectedSrc = '/api/pictures/latest?t=' + Date.now();
                img.src = expectedSrc;
                img.style.display = 'block';
                noImg.style.display = 'none';
            }
        })
        .catch(err => console.error('Status poll error:', err));
}

// -----------------------------------------------------------------------
// Gallery
// -----------------------------------------------------------------------

let galleryLoaded = false;

function loadGallery() {
    const grid = document.getElementById('gallery-grid');
    if (!grid) return;

    grid.innerHTML = '<p class="info-text">Chargement de la galerie...</p>';

    fetch('/api/pictures/gallery')
        .then(r => r.json())
        .then(data => {
            const pictures = data.pictures || [];
            if (pictures.length === 0) {
                grid.innerHTML = '<p class="info-text">Aucune photo dans la galerie.</p>';
                return;
            }

            grid.innerHTML = '';
            pictures.forEach((pic, idx) => {
                const card = document.createElement('div');
                card.className = 'gallery-card';

                const img = document.createElement('img');
                img.src = '/api/pictures/file/' + pic.filename.split('/').map(encodeURIComponent).join('/');
                img.alt = pic.filename;
                img.loading = 'lazy';
                // Store filename for printing
                img.dataset.filename = pic.filename;
                img.onclick = function() { openLightbox(this.src, this.dataset.filename); };

                const label = document.createElement('div');
                label.className = 'gallery-label';
                // Show date
                const date = new Date(pic.mtime * 1000);
                label.textContent = date.toLocaleDateString('fr-FR') + ' ' +
                                    date.toLocaleTimeString('fr-FR', {hour:'2-digit', minute:'2-digit'});

                card.appendChild(img);
                card.appendChild(label);
                grid.appendChild(card);
            });

            galleryLoaded = true;
        })
        .catch(err => {
            console.error('Gallery error:', err);
            grid.innerHTML = '<p class="info-text">Erreur de chargement de la galerie.</p>';
        });
}

// -----------------------------------------------------------------------
// Lightbox
// -----------------------------------------------------------------------

// Current lightbox filename (for printing)
let currentLightboxFilename = null;

function openLightbox(src, filename) {
    const lb = document.getElementById('lightbox');
    const img = document.getElementById('lightbox-img');
    if (!lb || !img) return;

    img.src = src;
    currentLightboxFilename = filename || null;
    lb.style.display = 'flex';
    document.body.style.overflow = 'hidden';

    // Reset print button state
    const printBtn = document.getElementById('lightbox-print-btn');
    if (printBtn) {
        printBtn.disabled = false;
        printBtn.textContent = '🖨️ Imprimer cette photo';
    }
    // Hide status
    const statusEl = document.getElementById('lightbox-status');
    if (statusEl) statusEl.style.display = 'none';
}

function closeLightbox(event) {
    // Don't close if clicking on controls
    if (event && event.target && (
        event.target.closest('.lightbox-controls') ||
        event.target.closest('.lightbox-close') === null && event.target.id !== 'lightbox'
    )) {
        // Only close if clicking the backdrop or the close button
        if (event.target.id !== 'lightbox' && !event.target.classList.contains('lightbox-close')) {
            return;
        }
    }
    const lb = document.getElementById('lightbox');
    if (!lb) return;
    lb.style.display = 'none';
    document.body.style.overflow = '';
    currentLightboxFilename = null;
}

function printFromLightbox(event) {
    event.stopPropagation();

    if (!currentLightboxFilename) {
        showLightboxStatus('❌ Aucun fichier sélectionné', 'error');
        return;
    }

    const printBtn = document.getElementById('lightbox-print-btn');
    if (printBtn) {
        printBtn.disabled = true;
        printBtn.textContent = '⏳ Impression en cours...';
    }

    const encodedPath = currentLightboxFilename.split('/').map(encodeURIComponent).join('/');

    fetch('/api/pictures/print/' + encodedPath, { method: 'POST' })
        .then(r => r.json())
        .then(data => {
            if (data.success) {
                showLightboxStatus('✅ Impression lancée sur ' + data.printer + ' (job #' + data.job_id + ')', 'success');
                if (printBtn) {
                    printBtn.textContent = '✅ Envoyé !';
                    setTimeout(() => {
                        printBtn.disabled = false;
                        printBtn.textContent = '🖨️ Imprimer cette photo';
                    }, 3000);
                }
            } else {
                showLightboxStatus('❌ Erreur: ' + (data.error || 'inconnue'), 'error');
                if (printBtn) {
                    printBtn.disabled = false;
                    printBtn.textContent = '🖨️ Imprimer cette photo';
                }
            }
        })
        .catch(err => {
            showLightboxStatus('❌ Erreur réseau: ' + err.message, 'error');
            if (printBtn) {
                printBtn.disabled = false;
                printBtn.textContent = '🖨️ Imprimer cette photo';
            }
        });
}

function showLightboxStatus(message, type) {
    const el = document.getElementById('lightbox-status');
    if (!el) return;
    el.textContent = message;
    el.className = 'lightbox-status lightbox-status-' + (type || 'info');
    el.style.display = 'block';
    setTimeout(() => { el.style.display = 'none'; }, 5000);
}

// Close lightbox on Escape key
document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') closeLightbox();
});

// -----------------------------------------------------------------------
// Start polling
// -----------------------------------------------------------------------

setInterval(refreshStatus, POLL_INTERVAL);
document.addEventListener('DOMContentLoaded', refreshStatus);