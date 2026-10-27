<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Math Shooter: Misi Pecahan, Desimal & Persen</title>
    <!-- Tailwind CSS -->
    <script src="https://cdn.tailwindcss.com"></script>
    <!-- Font Awesome Icons -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <!-- Google Fonts -->
    <link href="https://fonts.googleapis.com/css2?family=Fredoka:wght@400;600;700&family=Nunito:wght@400;700;800&display=swap" rel="stylesheet">
    
    <!-- MediaPipe Hands CDN -->
    <script src="https://cdn.jsdelivr.net/npm/@mediapipe/camera_utils/camera_utils.js" crossorigin="anonymous"></script>
    <script src="https://cdn.jsdelivr.net/npm/@mediapipe/hands/hands.js" crossorigin="anonymous"></script>

    <style>
        body {
            font-family: 'Nunito', sans-serif;
            background: linear-gradient(135deg, #0f172a 0%, #1e1b4b 50%, #311042 100%);
            color: #fff;
            user-select: none;
            overflow-x: hidden;
        }
        .font-header {
            font-family: 'Fredoka', cursive;
        }
        /* Custom Game Canvas Overlay */
        #game-canvas {
            touch-action: none;
        }
        .glass-panel {
            background: rgba(255, 255, 255, 0.1);
            backdrop-filter: blur(12px);
            -webkit-backdrop-filter: blur(12px);
            border: 1px solid rgba(255, 255, 255, 0.2);
        }
        .target-card {
            transition: transform 0.2s ease, box-shadow 0.2s ease;
        }
        .target-card:hover {
            transform: scale(1.03);
            box-shadow: 0 0 25px rgba(59, 130, 246, 0.6);
        }
        /* Custom Crosshair Pulse */
        @keyframes laser-pulse {
            0% { transform: translate(-50%, -50%) scale(1); opacity: 0.9; }
            50% { transform: translate(-50%, -50%) scale(1.15); opacity: 1; }
            100% { transform: translate(-50%, -50%) scale(1); opacity: 0.9; }
        }
        .crosshair-active {
            animation: laser-pulse 0.6s infinite ease-in-out;
        }
        /* Laser beam effect */
        .laser-line {
            position: absolute;
            pointer-events: none;
            background: linear-gradient(90deg, rgba(239, 68, 68, 0.8), rgba(245, 158, 11, 1), rgba(255, 255, 255, 1));
            box-shadow: 0 0 15px #f59e0b, 0 0 30px #ef4444;
            transform-origin: 0% 50%;
            z-index: 45;
        }
        /* Floating animations */
        @keyframes float {
            0%, 100% { transform: translateY(0px); }
            50% { transform: translateY(-10px); }
        }
        .animate-float {
            animation: float 4s ease-in-out infinite;
        }
    </style>
</head>
<body class="min-h-screen flex flex-col justify-between items-center relative overflow-hidden">

    <!-- Top Info Bar / Header -->
    <header class="w-full max-w-6xl mx-auto px-4 py-3 flex justify-between items-center z-20">
        <div class="flex items-center space-x-3">
            <div class="bg-gradient-to-r from-cyan-500 to-blue-600 p-2.5 rounded-2xl shadow-lg flex items-center justify-center">
                <i class="fa-solid fa-bullseye text-2xl text-white"></i>
            </div>
            <div>
                <h1 class="font-header text-xl md:text-2xl font-bold bg-clip-text text-transparent bg-gradient-to-r from-cyan-400 to-pink-400">Math Shooter</h1>
                <p class="text-xs text-slate-300 hidden sm:block">Fase B / Kelas IV SD • Pecahan, Desimal & Persen</p>
            </div>
        </div>

        <!-- Camera Status & Controls Header -->
        <div class="flex items-center space-x-2 sm:space-x-4">
            <div id="cam-status-badge" class="glass-panel px-3 py-1.5 rounded-full flex items-center space-x-2 text-xs">
                <span id="cam-indicator" class="w-2.5 h-2.5 rounded-full bg-red-500"></span>
                <span id="cam-status-text" class="text-slate-300 font-medium">Kamera Mati</span>
            </div>
            <button id="toggle-cam-btn" onclick="toggleCamera()" class="bg-indigo-600 hover:bg-indigo-500 active:scale-95 text-white text-xs sm:text-sm px-3.5 py-2 rounded-xl font-bold transition flex items-center space-x-2 shadow-md">
                <i class="fa-solid fa-camera"></i>
                <span id="cam-btn-text">Aktifkan Kamera</span>
            </button>
        </div>
    </header>

    <!-- Main Container -->
    <main class="w-full max-w-6xl mx-auto px-4 flex-1 flex flex-col justify-center items-center relative z-10 my-2">

        <!-- SCREEN 1: WELCOME SCREEN -->
        <section id="screen-welcome" class="w-full max-w-4xl glass-panel rounded-3xl p-6 md:p-10 text-center shadow-2xl relative overflow-hidden my-auto">
            <div class="absolute -top-24 -left-24 w-48 h-48 bg-pink-500/20 rounded-full blur-3xl"></div>
            <div class="absolute -bottom-24 -right-24 w-48 h-48 bg-cyan-500/20 rounded-full blur-3xl"></div>

            <span class="inline-block bg-cyan-500/20 text-cyan-300 text-xs md:text-sm font-bold px-4 py-1.5 rounded-full border border-cyan-500/30 mb-4">
                <i class="fa-solid fa-graduation-cap mr-1"></i> Media Pembelajaran Interactive AR Motion Gesture
            </span>

            <h2 class="font-header text-3xl md:text-5xl font-extrabold text-white mb-3 tracking-wide">
                Misi Matematika: <span class="bg-clip-text text-transparent bg-gradient-to-r from-amber-300 via-pink-400 to-cyan-300">Tembak Jawaban!</span>
            </h2>

            <div class="bg-slate-900/60 rounded-2xl p-4 text-left border border-slate-700/50 mb-6 text-xs md:text-sm text-slate-200 space-y-2">
                <p><strong><i class="fa-solid fa-bullseye text-pink-400 mr-2"></i>Tujuan Pembelajaran (TP):</strong></p>
                <ul class="list-disc list-inside space-y-1 text-slate-300 pl-2">
                    <li>Menentukan bentuk desimal & persen dari pecahan persepuluh dan perseratus.</li>
                    <li>Menentukan bentuk pecahan persepuluh atau perseratus dari desimal & persen.</li>
                    <li>Menyelesaikan 15 Misi Tembak Jawaban Benar dengan gestur tangan!</li>
                </ul>
            </div>

            <!-- Avatar & Hero Graphic -->
            <div class="flex justify-center items-center space-x-6 my-6">
                <div class="text-center animate-float">
                    <div class="w-24 h-24 md:w-32 md:h-32 bg-gradient-to-br from-indigo-500 to-purple-700 rounded-full flex items-center justify-center border-4 border-cyan-400 shadow-xl mx-auto">
                        <i class="fa-solid fa-user-ninja text-4xl md:text-6xl text-amber-300"></i>
                    </div>
                    <span class="text-xs text-cyan-300 font-bold mt-2 block">Kapten Matematika</span>
                </div>
            </div>

            <div class="flex flex-col sm:flex-row justify-center items-center gap-4 mt-6">
                <button onclick="showInstructions()" class="w-full sm:w-auto bg-gradient-to-r from-cyan-500 to-blue-600 hover:from-cyan-400 hover:to-blue-500 text-white font-header font-bold text-lg px-8 py-3.5 rounded-2xl shadow-lg hover:shadow-cyan-500/30 active:scale-95 transition flex items-center justify-center space-x-2">
                    <i class="fa-solid fa-play"></i>
                    <span>MULAI PETUALANGAN</span>
                </button>
            </div>
        </section>

        <!-- SCREEN 2: INSTRUCTIONS SCREEN -->
        <section id="screen-instructions" class="hidden w-full max-w-4xl glass-panel rounded-3xl p-6 md:p-8 text-center shadow-2xl my-auto">
            <h2 class="font-header text-2xl md:text-4xl font-bold text-amber-300 mb-6">
                <i class="fa-solid fa-hand-pointer mr-2"></i> Cara Bermain AR Motion Gesture
            </h2>

            <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-8 text-left">
                <div class="bg-slate-900/60 p-5 rounded-2xl border border-slate-700/60 flex flex-col items-center text-center">
                    <div class="w-14 h-14 bg-cyan-500/20 text-cyan-400 rounded-2xl flex items-center justify-center text-2xl mb-3">
                        <i class="fa-solid fa-hand-point-up"></i>
                    </div>
                    <h3 class="font-bold text-lg text-white mb-1">1. Bidik Target</h3>
                    <p class="text-xs text-slate-300">Arahkan **ujung jari telunjuk** kamu ke layar untuk menggerakkan kursor bidikan.</p>
                </div>

                <div class="bg-slate-900/60 p-5 rounded-2xl border border-slate-700/60 flex flex-col items-center text-center">
                    <div class="w-14 h-14 bg-pink-500/20 text-pink-400 rounded-2xl flex items-center justify-center text-2xl mb-3">
                        <i class="fa-solid fa-hand-back-fist"></i>
                    </div>
                    <h3 class="font-bold text-lg text-white mb-1">2. Cubit (Pinch) untuk Menembak</h3>
                    <p class="text-xs text-slate-300">Satukan **ujung jempol & telunjuk** untuk menembak target jawaban yang benar!</p>
                </div>

                <div class="bg-slate-900/60 p-5 rounded-2xl border border-slate-700/60 flex flex-col items-center text-center">
                    <div class="w-14 h-14 bg-amber-500/20 text-amber-400 rounded-2xl flex items-center justify-center text-2xl mb-3">
                        <i class="fa-solid fa-computer-mouse"></i>
                    </div>
                    <h3 class="font-bold text-lg text-white mb-1">3. Mode Cadangan</h3>
                    <p class="text-xs text-slate-300">Tanpa kamera? Kamu tetap bisa menembak dengan **klik mouse** atau **sentuhan layar**.</p>
                </div>
            </div>

            <div class="bg-indigo-950/60 p-4 rounded-xl border border-indigo-500/30 mb-6 text-xs text-indigo-200">
                <i class="fa-solid fa-lightbulb text-amber-400 mr-2 text-sm"></i> Tip: Pastikan pencahayaan ruangan cukup baik agar tangan terdeteksi dengan sempurna oleh webcam!
            </div>

            <button onclick="startGame()" class="bg-gradient-to-r from-emerald-500 to-teal-600 hover:from-emerald-400 hover:to-teal-500 text-white font-header font-bold text-xl px-10 py-4 rounded-2xl shadow-lg hover:shadow-emerald-500/30 active:scale-95 transition">
                SIAP, MULAI MENEMBAK! <i class="fa-solid fa-rocket ml-2"></i>
            </button>
        </section>

        <!-- SCREEN 3: GAMEPLAY ARENA -->
        <section id="screen-game" class="hidden w-full flex flex-col items-center relative">
            
            <!-- Game HUD (Score, Lives, Progress) -->
            <div class="w-full glass-panel rounded-2xl p-4 mb-4 flex justify-between items-center shadow-lg">
                <div class="flex items-center space-x-4">
                    <!-- Lives -->
                    <div class="flex items-center space-x-1 bg-slate-900/60 px-3 py-1.5 rounded-xl border border-slate-700">
                        <span class="text-xs text-slate-400 font-bold mr-1">Nyawa:</span>
                        <div id="lives-container" class="flex space-x-1 text-pink-500 text-lg">
                            <i class="fa-solid fa-heart"></i>
                            <i class="fa-solid fa-heart"></i>
                            <i class="fa-solid fa-heart"></i>
                        </div>
                    </div>
                    <!-- Score -->
                    <div class="bg-slate-900/60 px-4 py-1.5 rounded-xl border border-slate-700">
                        <span class="text-xs text-slate-400 font-bold mr-2">Skor:</span>
                        <span id="score-text" class="font-header font-bold text-xl text-amber-400">0</span>
                    </div>
                </div>

                <!-- Soal Progress -->
                <div class="flex items-center space-x-3">
                    <div class="bg-slate-900/60 px-4 py-1.5 rounded-xl border border-slate-700">
                        <span class="text-xs text-slate-400 font-bold mr-2">Soal:</span>
                        <span id="question-progress" class="font-header font-bold text-lg text-cyan-400">1 / 15</span>
                    </div>
                    <button onclick="pauseGame()" class="bg-slate-800 hover:bg-slate-700 p-2.5 rounded-xl text-slate-300 transition">
                        <i class="fa-solid fa-pause"></i>
                    </button>
                </div>
            </div>

            <!-- Question Box -->
            <div class="w-full bg-gradient-to-r from-indigo-900/90 to-purple-900/90 border-2 border-cyan-400/50 rounded-3xl p-5 md:p-7 text-center shadow-xl mb-6 relative">
                <span class="absolute -top-3.5 left-1/2 -translate-x-1/2 bg-cyan-500 text-slate-950 text-xs font-black uppercase tracking-wider px-4 py-0.5 rounded-full shadow">
                    Misi Matematika
                </span>
                <h2 id="question-text" class="font-header text-2xl md:text-4xl font-extrabold text-white leading-relaxed">
                    3/10 = ... (dalam bentuk desimal)
                </h2>
            </div>

            <!-- Target Answer Cards Grid (4 Options) -->
            <div id="targets-grid" class="w-full grid grid-cols-1 sm:grid-cols-2 gap-4 md:gap-6 relative">
                <!-- Target Cards will be populated by JS dynamically -->
            </div>

            <!-- Hand Gesture Pointer/Crosshair Overlay Visual -->
            <div id="crosshair" class="fixed pointer-events-none w-14 h-14 rounded-full border-2 border-cyan-400 flex items-center justify-center transition-all duration-75 z-50 -translate-x-1/2 -translate-y-1/2 shadow-lg shadow-cyan-500/50">
                <div class="w-3 h-3 bg-red-500 rounded-full"></div>
                <!-- Crosshair lines -->
                <div class="absolute w-full h-0.5 bg-cyan-400/60"></div>
                <div class="absolute h-full w-0.5 bg-cyan-400/60"></div>
            </div>

            <!-- Laser Beam Container -->
            <div id="laser-container" class="pointer-events-none fixed inset-0 z-40"></div>

        </section>

        <!-- SCREEN 4: EVALUATION / FEEDBACK MODAL -->
        <div id="modal-feedback" class="hidden fixed inset-0 bg-slate-950/80 backdrop-blur-md z-50 flex items-center justify-center p-4">
            <div class="max-w-md w-full glass-panel rounded-3xl p-6 text-center border-2 shadow-2xl animate-float">
                <div id="feedback-icon" class="w-20 h-20 rounded-full flex items-center justify-center text-4xl mx-auto mb-4 shadow-lg">
                    <!-- Icon populated by JS -->
                </div>
                <h3 id="feedback-title" class="font-header text-2xl md:text-3xl font-extrabold mb-2">Benar Sekali!</h3>
                <p id="feedback-msg" class="text-sm text-slate-300 mb-4">Kamu mendapatkan 100 Poin!</p>

                <!-- Explanation Box -->
                <div class="bg-slate-900/80 p-4 rounded-2xl text-left border border-slate-700 mb-6">
                    <div class="text-xs font-bold text-cyan-400 mb-1 flex items-center">
                        <i class="fa-solid fa-book-open mr-1.5"></i> Pembahasan:
                    </div>
                    <p id="feedback-explanation" class="text-xs md:text-sm text-slate-200 leading-relaxed">
                        3/10 berarti 3 dibagi 10. Karena persepuluh, ada 1 angka di belakang koma, yaitu 0,3.
                    </p>
                </div>

                <button onclick="nextQuestion()" class="w-full bg-gradient-to-r from-cyan-500 to-blue-600 hover:from-cyan-400 hover:to-blue-500 text-white font-header font-bold text-lg py-3 rounded-2xl shadow-lg active:scale-95 transition">
                    Lanjut Soal Berikutnya <i class="fa-solid fa-arrow-right ml-2"></i>
                </button>
            </div>
        </div>

        <!-- SCREEN 5: GAME OVER / RESULT SCREEN -->
        <section id="screen-result" class="hidden w-full max-w-3xl glass-panel rounded-3xl p-6 md:p-10 text-center shadow-2xl my-auto">
            <div id="result-badge" class="w-24 h-24 rounded-full flex items-center justify-center text-5xl mx-auto mb-4 border-4 shadow-2xl">
                <!-- Dynamic Trophy/Skull icon -->
            </div>

            <h2 id="result-title" class="font-header text-3xl md:text-5xl font-extrabold text-white mb-2">Misi Selesai!</h2>
            <p id="result-subtitle" class="text-sm text-slate-300 mb-6">Berikut adalah hasil pencapaian petualanganmu:</p>

            <!-- Result Stats Cards -->
            <div class="grid grid-cols-2 md:grid-cols-4 gap-3 mb-6">
                <div class="bg-slate-900/60 p-3.5 rounded-2xl border border-slate-700 text-center">
                    <span class="text-xs text-slate-400 block font-bold">Skor Akhir</span>
                    <span id="res-score" class="font-header text-2xl md:text-3xl text-amber-400 font-bold">0</span>
                </div>
                <div class="bg-slate-900/60 p-3.5 rounded-2xl border border-slate-700 text-center">
                    <span class="text-xs text-slate-400 block font-bold">Benar</span>
                    <span id="res-correct" class="font-header text-2xl md:text-3xl text-emerald-400 font-bold">0 / 15</span>
                </div>
                <div class="bg-slate-900/60 p-3.5 rounded-2xl border border-slate-700 text-center">
                    <span class="text-xs text-slate-400 block font-bold">Salah</span>
                    <span id="res-wrong" class="font-header text-2xl md:text-3xl text-pink-500 font-bold">0</span>
                </div>
                <div class="bg-slate-900/60 p-3.5 rounded-2xl border border-slate-700 text-center">
                    <span class="text-xs text-slate-400 block font-bold">Akurasi</span>
                    <span id="res-accuracy" class="font-header text-2xl md:text-3xl text-cyan-400 font-bold">0%</span>
                </div>
            </div>

            <!-- Motivation Note -->
            <div id="result-motivation" class="bg-indigo-950/60 p-4 rounded-2xl border border-indigo-500/30 text-xs md:text-sm text-indigo-200 mb-8">
                Hebat sekali! Kamu sudah menguasai konsep dasar Pecahan, Desimal, dan Persen dengan sangat baik!
            </div>

            <div class="flex flex-col sm:flex-row justify-center items-center gap-4">
                <button onclick="restartGame()" class="w-full sm:w-auto bg-gradient-to-r from-emerald-500 to-teal-600 hover:from-emerald-400 hover:to-teal-500 text-white font-header font-bold text-lg px-8 py-3.5 rounded-2xl shadow-lg active:scale-95 transition">
                    <i class="fa-solid fa-rotate-right mr-2"></i> MAIN LAGI
                </button>
                <button onclick="goHome()" class="w-full sm:w-auto bg-slate-800 hover:bg-slate-700 text-slate-200 font-header font-bold text-lg px-8 py-3.5 rounded-2xl border border-slate-600 active:scale-95 transition">
                    <i class="fa-solid fa-house mr-2"></i> BERANDA
                </button>
            </div>
        </section>

    </main>

    <!-- Hidden Video & Canvas elements for MediaPipe Hand Tracking -->
    <video id="webcam-video" class="hidden" playsinline></video>
    <canvas id="output-canvas" class="hidden"></canvas>

    <!-- Footer -->
    <footer class="w-full py-3 text-center text-xs text-slate-400 z-20">
        Math Shooter AR Motion Gesture • Didukung oleh MediaPipe & Web Audio API
    </footer>

    <!-- JavaScript Logic -->
    <script>
        /* ==========================================================================
           1. DATA SOAL MATEMATIKA (15 SOAL FASE B KELAS IV SD)
           ========================================================================== */
        const mathQuestions = [
            {
                q: "\\(\\frac{3}{10}\\) = ... dalam bentuk desimal",
                options: ["0,3", "0,03", "3,0", "0,33"],
                answer: 0,
                explain: "\\(\\frac{3}{10}\\) memiliki 1 angka nol pada penyebut persepuluh, sehingga nilainya 0,3."
            },
            {
                q: "\\(\\frac{7}{10}\\) = ... %",
                options: ["7%", "70%", "0,7%", "700%"],
                answer: 1,
                explain: "Persepuluh diubah ke persen dikali 10: \\(\\frac{7}{10} = \\frac{70}{100} = 70\\%\\)."
            },
            {
                q: "\\(\\frac{25}{100}\\) = ... dalam bentuk desimal",
                options: ["2,5", "0,025", "0,25", "25,0"],
                answer: 2,
                explain: "\\(\\frac{25}{100}\\) adalah perseratus, artinya ada 2 angka di belakang koma, yaitu 0,25."
            },
            {
                q: "\\(\\frac{45}{100}\\) = ... %",
                options: ["4,5%", "45%", "0,45%", "450%"],
                answer: 1,
                explain: "Pecahan perseratus langsung menunjukkan persen: \\(\\frac{45}{100} = 45\\%\\)."
            },
            {
                q: "0,7 = ... dalam bentuk pecahan",
                options: ["\\(\\frac{7}{100}\\)", "\\(\\frac{7}{10}\\)", "\\(\\frac{70}{10}\\)", "\\(\\frac{1}{7}\\)"],
                answer: 1,
                explain: "Karena ada 1 angka di belakang koma (0,7), maka bentuk pecahannya adalah \\(\\frac{7}{10}\\)."
            },
            {
                q: "0,35 = ... dalam bentuk pecahan",
                options: ["\\(\\frac{35}{10}\\)", "\\(\\frac{3,5}{100}\\)", "\\(\\frac{35}{100}\\)", "\\(\\frac{53}{100}\\)"],
                answer: 2,
                explain: "Ada 2 angka di belakang koma (0,35), maka bentuk pecahannya adalah \\(\\frac{35}{100}\\)."
            },
            {
                q: "40% = ... dalam bentuk pecahan persepuluh atau perseratus",
                options: ["\\(\\frac{4}{100}\\)", "\\(\\frac{40}{10}\\)", "\\(\\frac{4}{10}\\)", "\\(\\frac{0,4}{10}\\)"],
                answer: 2,
                explain: "40% = \\(\\frac{40}{100}\\). Jika disederhanakan dibagi 10, menjadi \\(\\frac{4}{10}\\)."
            },
            {
                q: "65% = ... dalam bentuk pecahan perseratus",
                options: ["\\(\\frac{65}{100}\\)", "\\(\\frac{65}{10}\\)", "\\(\\frac{6,5}{100}\\)", "\\(\\frac{650}{100}\\)"],
                answer: 0,
                explain: "Persen artinya per seratus, jadi 65% sama dengan \\(\\frac{65}{100}\\)."
            },
            {
                q: "Bentuk desimal yang setara dengan \\(\\frac{9}{10}\\) adalah ...",
                options: ["0,09", "9,0", "0,9", "0,99"],
                answer: 2,
                explain: "\\(\\frac{9}{10}\\) diubah ke bentuk desimal menghasilkan 0,9."
            },
            {
                q: "Bentuk persen yang setara dengan 0,5 adalah ...",
                options: ["5%", "50%", "0,5%", "500%"],
                answer: 1,
                explain: "0,5 = \\(\\frac{5}{10} = \\frac{50}{100} = 50\\%\\)."
            },
            {
                q: "\\(\\frac{80}{100}\\) jika diubah menjadi pecahan persepuluh adalah ...",
                options: ["\\(\\frac{8}{100}\\)", "\\(\\frac{8}{10}\\)", "\\(\\frac{80}{10}\\)", "\\(\\frac{0,8}{10}\\)"],
                answer: 1,
                explain: "Membagi pembilang dan penyebut dengan 10: \\(\\frac{80 \\div 10}{100 \\div 10} = \\frac{8}{10}\\)."
            },
            {
                q: "0,06 = ... dalam bentuk persen atau pecahan",
                options: ["6%", "60%", "\\(\\frac{6}{10}\\)", "0,6%"],
                answer: 0,
                explain: "0,06 = \\(\\frac{6}{100}\\) yang berarti 6%."
            },
            {
                q: "Bentuk desimal dari 15% adalah ...",
                options: ["1,5", "0,15", "0,015", "15,0"],
                answer: 1,
                explain: "15% = \\(\\frac{15}{100} = 0,15\\)."
            },
            {
                q: "Bentuk pecahan perseratus dari 0,82 adalah ...",
                options: ["\\(\\frac{82}{10}\\)", "\\(\\frac{8,2}{100}\\)", "\\(\\frac{82}{100}\\)", "\\(\\frac{820}{100}\\)"],
                answer: 2,
                explain: "Dua angka di belakang koma (0,82) berarti \\(\\frac{82}{100}\\)."
            },
            {
                q: "Pernyataan berikut yang BENAR adalah ...",
                options: [
                    "\\(\\frac{5}{10} = 0,05\\)",
                    "\\(\\frac{30}{100} = 30\\%\\)",
                    "0,4 = 4%",
                    "\\(\\frac{10}{100} = 1,0\\)"
                ],
                answer: 1,
                explain: "\\(\\frac{30}{100}\\) memang setara dengan 30%."
            }
        ];

        /* Helper to format math text into clean HTML representations */
        function formatMathHTML(text) {
            return text.replace(/\\\(?\\frac\{([^}]+)\}\{([^}]+)\}\\\)?/g, '<span class="inline-flex flex-col text-center align-middle mx-1"><span class="border-b-2 border-current px-1 font-bold leading-tight">$1</span><span class="px-1 font-bold leading-tight">$2</span></span>');
        }

        /* ==========================================================================
           2. WEB AUDIO API SOUND GENERATOR (NO EXTERNAL AUDIO FILES)
           ========================================================================== */
        const AudioCtx = window.AudioContext || window.webkitAudioContext;
        let audioCtx = null;

        function initAudio() {
            if (!audioCtx) {
                audioCtx = new AudioCtx();
            }
            if (audioCtx.state === 'suspended') {
                audioCtx.resume();
            }
        }

        function playLaserSound() {
            if (!audioCtx) return;
            const osc = audioCtx.createOscillator();
            const gain = audioCtx.createGain();
            osc.type = 'sawtooth';
            osc.frequency.setValueAtTime(800, audioCtx.currentTime);
            osc.frequency.exponentialRampToValueAtTime(100, audioCtx.currentTime + 0.15);
            gain.gain.setValueAtTime(0.3, audioCtx.currentTime);
            gain.gain.linearRampToValueAtTime(0.01, audioCtx.currentTime + 0.15);
            osc.connect(gain);
            gain.connect(audioCtx.destination);
            osc.start();
            osc.stop(audioCtx.currentTime + 0.15);
        }

        function playCorrectSound() {
            if (!audioCtx) return;
            const now = audioCtx.currentTime;
            const osc = audioCtx.createOscillator();
            const gain = audioCtx.createGain();
            osc.type = 'triangle';
            osc.frequency.setValueAtTime(523.25, now); // C5
            osc.frequency.setValueAtTime(659.25, now + 0.1); // E5
            osc.frequency.setValueAtTime(783.99, now + 0.2); // G5
            osc.frequency.setValueAtTime(1046.50, now + 0.3); // C6
            gain.gain.setValueAtTime(0.3, now);
            gain.gain.linearRampToValueAtTime(0.01, now + 0.5);
            osc.connect(gain);
            gain.connect(audioCtx.destination);
            osc.start();
            osc.stop(now + 0.5);
        }

        function playWrongSound() {
            if (!audioCtx) return;
            const now = audioCtx.currentTime;
            const osc = audioCtx.createOscillator();
            const gain = audioCtx.createGain();
            osc.type = 'sawtooth';
            osc.frequency.setValueAtTime(250, now);
            osc.frequency.linearRampToValueAtTime(100, now + 0.3);
            gain.gain.setValueAtTime(0.4, now);
            gain.gain.linearRampToValueAtTime(0.01, now + 0.3);
            osc.connect(gain);
            gain.connect(audioCtx.destination);
            osc.start();
            osc.stop(now + 0.3);
        }

        function playVictorySound() {
            if (!audioCtx) return;
            const now = audioCtx.currentTime;
            const notes = [400, 500, 600, 800, 1000];
            notes.forEach((freq, idx) => {
                const osc = audioCtx.createOscillator();
                const gain = audioCtx.createGain();
                osc.type = 'sine';
                osc.frequency.setValueAtTime(freq, now + idx * 0.12);
                gain.gain.setValueAtTime(0.3, now + idx * 0.12);
                gain.gain.linearRampToValueAtTime(0.01, now + idx * 0.12 + 0.2);
                osc.connect(gain);
                gain.connect(audioCtx.destination);
                osc.start(now + idx * 0.12);
                osc.stop(now + idx * 0.12 + 0.2);
            });
        }

        /* ==========================================================================
           3. GAME STATE MANAGEMENT
           ========================================================================== */
        let currentQuestionIdx = 0;
        let score = 0;
        let lives = 3;
        let correctCount = 0;
        let wrongCount = 0;
        let isAnswerLocked = false;

        // Pointer / Crosshair position
        let pointerX = window.innerWidth / 2;
        let pointerY = window.innerHeight / 2;
        let lastPinchState = false;
        let pinchCooldown = false;

        /* ==========================================================================
           4. MEDIAPIPE HAND TRACKING & CAMERA CONTROL
           ========================================================================== */
        let videoElement = document.getElementById('webcam-video');
        let camera = null;
        let hands = null;
        let isCameraActive = false;

        function initMediaPipe() {
            hands = new Hands({
                locateFile: (file) => `https://cdn.jsdelivr.net/npm/@mediapipe/hands/${file}`
            });

            hands.setOptions({
                maxNumHands: 1,
                modelComplexity: 1,
                minDetectionConfidence: 0.6,
                minTrackingConfidence: 0.6
            });

            hands.onResults(onHandResults);
        }

        async function toggleCamera() {
            initAudio();
            const btnText = document.getElementById('cam-btn-text');
            const statusIndicator = document.getElementById('cam-indicator');
            const statusText = document.getElementById('cam-status-text');

            if (isCameraActive) {
                // Stop camera
                if (camera) {
                    await camera.stop();
                    camera = null;
                }
                isCameraActive = false;
                btnText.innerText = "Aktifkan Kamera";
                statusIndicator.className = "w-2.5 h-2.5 rounded-full bg-red-500";
                statusText.innerText = "Kamera Mati";
            } else {
                // Start camera
                if (!hands) initMediaPipe();

                camera = new Camera(videoElement, {
                    onFrame: async () => {
                        await hands.send({ image: videoElement });
                    },
                    width: 640,
                    height: 480
                });

                try {
                    await camera.start();
                    isCameraActive = true;
                    btnText.innerText = "Matikan Kamera";
                    statusIndicator.className = "w-2.5 h-2.5 rounded-full bg-emerald-400 animate-ping";
                    statusText.innerText = "Mendeteksi Tangan...";
                } catch (err) {
                    alert("Gagal mengakses kamera. Pastikan izin kamera diberikan!");
                    console.error("Camera error:", err);
                    isCameraActive = false;
                }
            }
        }

        function onHandResults(results) {
            const statusIndicator = document.getElementById('cam-indicator');
            const statusText = document.getElementById('cam-status-text');

            if (results.multiHandLandmarks && results.multiHandLandmarks.length > 0) {
                statusIndicator.className = "w-2.5 h-2.5 rounded-full bg-emerald-400";
                statusText.innerText = "Tangan Terdeteksi";

                const landmarks = results.multiHandLandmarks[0];
                
                // Landmark 8: Index Finger Tip
                const indexTip = landmarks[8];
                // Landmark 4: Thumb Tip
                const thumbTip = landmarks[4];

                // Convert normalized coordinates (0..1) to screen space (Mirrored horizontally for natural feel)
                const screenX = (1 - indexTip.x) * window.innerWidth;
                const screenY = indexTip.y * window.innerHeight;

                updateCrosshairPosition(screenX, screenY);

                // Calculate Euclidean distance between thumb tip & index tip for Pinch Gesture
                const distance = Math.hypot(
                    (indexTip.x - thumbTip.x),
                    (indexTip.y - thumbTip.y)
                );

                // Pinch threshold condition
                const isPinching = distance < 0.08;

                if (isPinching && !lastPinchState && !pinchCooldown) {
                    triggerShoot(screenX, screenY);
                    pinchCooldown = true;
                    setTimeout(() => { pinchCooldown = false; }, 400); // Debounce cooldown
                }
                lastPinchState = isPinching;
            } else {
                if (isCameraActive) {
                    statusIndicator.className = "w-2.5 h-2.5 rounded-full bg-amber-400";
                    statusText.innerText = "Mencari Tangan...";
                }
            }
        }

        /* Update Crosshair position */
        function updateCrosshairPosition(x, y) {
            pointerX = x;
            pointerY = y;
            const crosshair = document.getElementById('crosshair');
            crosshair.style.left = `${x}px`;
            crosshair.style.top = `${y}px`;
        }

        // Mouse & Touch Fallback Support
        window.addEventListener('mousemove', (e) => {
            if (!isCameraActive) {
                updateCrosshairPosition(e.clientX, e.clientY);
            }
        });

        window.addEventListener('click', (e) => {
            initAudio();
            // Allow manual shoot click if user clicks target directly or anywhere on active game screen
            const gameScreen = document.getElementById('screen-game');
            if (!gameScreen.classList.contains('hidden') && !isAnswerLocked) {
                triggerShoot(e.clientX, e.clientY);
            }
        });

        /* ==========================================================================
           5. SHOOTING & INTERACTION LOGIC
           ========================================================================== */
        function triggerShoot(x, y) {
            if (isAnswerLocked) return;

            playLaserSound();
            createLaserEffect(x, y);

            // Check if shot landed on any target option card
            const targetCards = document.querySelectorAll('.target-card');
            targetCards.forEach((card) => {
                const rect = card.getBoundingClientRect();
                if (
                    x >= rect.left &&
                    x <= rect.right &&
                    y >= rect.top &&
                    y <= rect.bottom
                ) {
                    const selectedOption = parseInt(card.getAttribute('data-option-index'));
                    handleAnswerSelection(selectedOption);
                }
            });
        }

        /* Create Cartoon Laser Animation Beam */
        function createLaserEffect(targetX, targetY) {
            const laserContainer = document.getElementById('laser-container');
            const laser = document.createElement('div');
            laser.className = 'laser-line';

            // Start laser from bottom-center of screen (Gun location)
            const startX = window.innerWidth / 2;
            const startY = window.innerHeight - 20;

            const angle = Math.atan2(targetY - startY, targetX - startX) * (180 / Math.PI);
            const distance = Math.hypot(targetX - startX, targetY - startY);

            laser.style.left = `${startX}px`;
            laser.style.top = `${startY}px`;
            laser.style.width = `${distance}px`;
            laser.style.height = `6px`;
            laser.style.transform = `rotate(${angle}deg)`;

            laserContainer.appendChild(laser);

            setTimeout(() => {
                laser.style.transition = 'opacity 0.2s ease-out';
                laser.style.opacity = '0';
                setTimeout(() => laser.remove(), 200);
            }, 100);
        }

        /* ==========================================================================
           6. GAMEPLAY FLOW & UI UPDATES
           ========================================================================== */
        function showInstructions() {
            initAudio();
            document.getElementById('screen-welcome').classList.add('hidden');
            document.getElementById('screen-instructions').classList.remove('hidden');
        }

        function startGame() {
            initAudio();
            currentQuestionIdx = 0;
            score = 0;
            lives = 3;
            correctCount = 0;
            wrongCount = 0;

            document.getElementById('screen-instructions').classList.add('hidden');
            document.getElementById('screen-result').classList.add('hidden');
            document.getElementById('screen-game').classList.remove('hidden');

            updateHUD();
            loadQuestion();
        }

        function loadQuestion() {
            isAnswerLocked = false;
            const qData = mathQuestions[currentQuestionIdx];

            // Update Header HUD
            document.getElementById('question-progress').innerText = `${currentQuestionIdx + 1} / ${mathQuestions.length}`;
            document.getElementById('question-text').innerHTML = formatMathHTML(qData.q);

            // Populate Answer Options Grid
            const grid = document.getElementById('targets-grid');
            grid.innerHTML = '';

            qData.options.forEach((optText, idx) => {
                const card = document.createElement('div');
                card.className = `target-card bg-slate-900/80 border-2 border-indigo-500/50 hover:border-cyan-400 rounded-3xl p-6 text-center cursor-pointer flex flex-col justify-center items-center shadow-xl relative overflow-hidden group select-none min-h-[120px]`;
                card.setAttribute('data-option-index', idx);

                card.innerHTML = `
                    <div class="absolute -top-6 -right-6 w-16 h-16 bg-cyan-500/10 rounded-full group-hover:scale-150 transition-all"></div>
                    <span class="absolute top-3 left-3 w-7 h-7 bg-indigo-600/60 text-indigo-200 text-xs font-bold rounded-full flex items-center justify-center">
                        ${String.fromCharCode(65 + idx)}
                    </span>
                    <div class="font-header text-2xl md:text-3xl font-extrabold text-amber-300">
                        ${formatMathHTML(optText)}
                    </div>
                `;
                grid.appendChild(card);
            });
        }

        function handleAnswerSelection(selectedIdx) {
            if (isAnswerLocked) return;
            isAnswerLocked = true;

            const qData = mathQuestions[currentQuestionIdx];
            const isCorrect = selectedIdx === qData.answer;

            const modal = document.getElementById('modal-feedback');
            const iconBox = document.getElementById('feedback-icon');
            const title = document.getElementById('feedback-title');
            const msg = document.getElementById('feedback-msg');
            const exp = document.getElementById('feedback-explanation');

            exp.innerHTML = formatMathHTML(qData.explain);

            if (isCorrect) {
                playCorrectSound();
                score += 100;
                correctCount++;

                iconBox.className = "w-20 h-20 rounded-full flex items-center justify-center text-4xl mx-auto mb-4 shadow-lg bg-emerald-500/20 text-emerald-400 border-2 border-emerald-400";
                iconBox.innerHTML = '<i class="fa-solid fa-circle-check"></i>';
                title.className = "font-header text-2xl md:text-3xl font-extrabold text-emerald-400 mb-2";
                title.innerText = "Tembakan Tepat! (Benar)";
                msg.innerText = "+100 Poin Tambahan!";
            } else {
                playWrongSound();
                lives--;
                wrongCount++;

                iconBox.className = "w-20 h-20 rounded-full flex items-center justify-center text-4xl mx-auto mb-4 shadow-lg bg-pink-500/20 text-pink-500 border-2 border-pink-500";
                iconBox.innerHTML = '<i class="fa-solid fa-circle-xmark"></i>';
                title.className = "font-header text-2xl md:text-3xl font-extrabold text-pink-500 mb-2";
                title.innerText = "Sasaran Meleset! (Salah)";
                msg.innerText = "Sayang sekali, nyawamu berkurang 1.";
            }

            updateHUD();
            modal.classList.remove('hidden');
        }

        function updateHUD() {
            document.getElementById('score-text').innerText = score;

            // Render hearts
            const container = document.getElementById('lives-container');
            container.innerHTML = '';
            for (let i = 0; i < 3; i++) {
                if (i < lives) {
                    container.innerHTML += '<i class="fa-solid fa-heart"></i>';
                } else {
                    container.innerHTML += '<i class="fa-regular fa-heart text-slate-600"></i>';
                }
            }
        }

        function nextQuestion() {
            document.getElementById('modal-feedback').classList.add('hidden');

            if (lives <= 0 || currentQuestionIdx >= mathQuestions.length - 1) {
                endGame();
            } else {
                currentQuestionIdx++;
                loadQuestion();
            }
        }

        function endGame() {
            document.getElementById('screen-game').classList.add('hidden');
            document.getElementById('screen-result').classList.remove('hidden');

            const total = mathQuestions.length;
            const accuracy = Math.round((correctCount / total) * 100);

            document.getElementById('res-score').innerText = score;
            document.getElementById('res-correct').innerText = `${correctCount} / ${total}`;
            document.getElementById('res-wrong').innerText = wrongCount;
            document.getElementById('res-accuracy').innerText = `${accuracy}%`;

            const badge = document.getElementById('result-badge');
            const title = document.getElementById('result-title');
            const mot = document.getElementById('result-motivation');

            if (lives > 0 && accuracy >= 70) {
                playVictorySound();
                badge.className = "w-24 h-24 rounded-full flex items-center justify-center text-5xl mx-auto mb-4 border-4 shadow-2xl bg-amber-500/20 text-amber-400 border-amber-400";
                badge.innerHTML = '<i class="fa-solid fa-trophy"></i>';
                title.innerText = "Misi Sukses Luar Biasa!";
                mot.innerText = "Selamat! Kamu adalah Penembak Jitu Matematika yang handal. Semua pecahan, desimal, dan persen berhasil kamu kuasai!";
            } else {
                badge.className = "w-24 h-24 rounded-full flex items-center justify-center text-5xl mx-auto mb-4 border-4 shadow-2xl bg-indigo-500/20 text-indigo-400 border-indigo-400";
                badge.innerHTML = '<i class="fa-solid fa-medal"></i>';
                title.innerText = "Petualangan Selesai!";
                mot.innerText = "Usaha yang bagus! Mari berlatih lebih giat lagi untuk meningkatkan akurasi tembakan matematikamu.";
            }
        }

        function pauseGame() {
            if (confirm("Ingin kembali ke beranda? Kemajuan permainan akan direset.")) {
                goHome();
            }
        }

        function restartGame() {
            startGame();
        }

        function goHome() {
            document.getElementById('screen-game').classList.add('hidden');
            document.getElementById('screen-instructions').classList.add('hidden');
            document.getElementById('screen-result').classList.add('hidden');
            document.getElementById('screen-welcome').classList.remove('hidden');
        }

        // Initialize crosshair default position center
        updateCrosshairPosition(window.innerWidth / 2, window.innerHeight / 2);
    </script>
</body>
</html>
