class AppScreenMeta {
  final String title;
  final String badge;
  final String type; // 'chart', 'flow', 'matrix', 'table', 'config'

  const AppScreenMeta({
    required this.title,
    required this.badge,
    this.type = 'flow',
  });
}

const Map<String, List<AppScreenMeta>> kEcosystemAppScreens = {
  'care4u': [
    AppScreenMeta(title: 'Patient Vitals & Daily Schedule', badge: 'LIVE VITALS STREAM', type: 'chart'),
    AppScreenMeta(title: 'HD Telehealth Consult Room', badge: 'E2EE WEBRTC VIDEO', type: 'flow'),
    AppScreenMeta(title: 'Medical Records & Diagnostic History', badge: 'ENCRYPTED EHR', type: 'matrix'),
    AppScreenMeta(title: 'Prescription & Pharmacy Dispatch', badge: 'DIGITAL RX VERIFIED', type: 'table'),
    AppScreenMeta(title: 'Biometric Sensor Sync & Telemetry', badge: 'BLE MEDICAL DEVICES', type: 'config'),
  ],
  'waptia': [
    AppScreenMeta(title: 'Curated Ecosystem Storefront', badge: '28 LIVE APPLICATIONS', type: 'chart'),
    AppScreenMeta(title: 'Research Publications & Whitepapers', badge: 'PEER-REVIEWED PAPERS', type: 'flow'),
    AppScreenMeta(title: 'Differential OTA Patch Registry', badge: '92% PAYLOAD SAVINGS', type: 'matrix'),
    AppScreenMeta(title: 'Cryptographic Signature Validation', badge: 'SHA-256 CHECKSUMS', type: 'table'),
    AppScreenMeta(title: 'Package Manager & Swarm Node Sync', badge: 'DECENTRALIZED MIRRORS', type: 'config'),
  ],
  'admin': [
    AppScreenMeta(title: 'Fleet App Management & Releases', badge: 'SUPERADMIN GOVERNANCE', type: 'chart'),
    AppScreenMeta(title: 'Internal Test Track Telemetry', badge: 'PLAY CONSOLE BRIDGE', type: 'flow'),
    AppScreenMeta(title: 'OTA Differential Manifest Auditing', badge: 'BSDIFF DEPLOYMENT', type: 'matrix'),
    AppScreenMeta(title: 'Role-Based Access Governance', badge: 'RBAC VERIFIED', type: 'table'),
    AppScreenMeta(title: 'Cluster Health & Node Telemetry', badge: 'ZERO-COST CLUSTER', type: 'config'),
  ],
  'lexi': [
    AppScreenMeta(title: 'Salon Storefront & Real-time Catalog', badge: 'LIVE INVENTORY', type: 'chart'),
    AppScreenMeta(title: 'Dark Store Automated Dispatch', badge: 'SUB-30 MIN FULFILLMENT', type: 'flow'),
    AppScreenMeta(title: 'B2B Wholesale Price Negotiation', badge: 'DYNAMIC TIER PRICING', type: 'matrix'),
    AppScreenMeta(title: 'Merchant Ledger & Settlement Stream', badge: 'INSTANT UPI SETTLEMENT', type: 'table'),
    AppScreenMeta(title: 'Supply Chain Routing & Warehouses', badge: 'MULTI-STORE POS', type: 'config'),
  ],
  'cyclomedusa': [
    AppScreenMeta(title: 'Relativistic Space Simulation Field', badge: '100K PARTICLES @ 60FPS', type: 'chart'),
    AppScreenMeta(title: 'Orbital Telemetry & Vector Velocity', badge: 'KEPLERIAN TRAJECTORIES', type: 'flow'),
    AppScreenMeta(title: 'Gravitational Potential Tensor Map', badge: 'GENERAL RELATIVITY', type: 'matrix'),
    AppScreenMeta(title: 'Black Hole Ergosphere & Raytracing', badge: 'GPU ACCELERATED', type: 'table'),
    AppScreenMeta(title: 'Simulation Constants & Physics Engine', badge: 'PRECISION G-CALC', type: 'config'),
  ],
  'dickinsonia': [
    AppScreenMeta(title: 'Multi-Channel Spatial Audio HUD', badge: '3D BINAURAL SOUND', type: 'chart'),
    AppScreenMeta(title: 'Real-Time DSP Filter Control Rack', badge: 'PARAMETRIC EQ & COMP', type: 'flow'),
    AppScreenMeta(title: 'FFT Spectrum & Harmonic Visualizer', badge: '192 KHZ / 32-BIT FLOAT', type: 'matrix'),
    AppScreenMeta(title: 'Low-Latency Stream Buffer Matrix', badge: 'ROUND-TRIP < 2.5MS', type: 'table'),
    AppScreenMeta(title: 'ASIO / CoreAudio Hardware Router', badge: 'ZERO DROPPED SAMPLES', type: 'config'),
  ],
  'ernietta': [
    AppScreenMeta(title: 'BLE Mesh Node Topology Network', badge: '250+ ACTIVE NODES', type: 'chart'),
    AppScreenMeta(title: 'Real-Time Packet Stream & Routing', badge: 'MULTI-HOP PROTOCOL', type: 'flow'),
    AppScreenMeta(title: 'Node Signal Strength & RSSI Radar', badge: 'AUTOMATED BEACONING', type: 'matrix'),
    AppScreenMeta(title: 'Cryptographic Mesh Key Exchange', badge: 'AES-CCM HARDWARE SEC', type: 'table'),
    AppScreenMeta(title: 'Gateway Configuration & Firmware OTA', badge: 'OTA MESH BROADCAST', type: 'config'),
  ],
  'fractofusus': [
    AppScreenMeta(title: 'Subnet Adaptive Topology Router', badge: 'BGP / OSPF / WIREGUARD', type: 'chart'),
    AppScreenMeta(title: 'Traffic Throughput & Latency Matrix', badge: '100 GBPS TELEMETRY', type: 'flow'),
    AppScreenMeta(title: 'Zero-Trust Firewall Policy Inspector', badge: 'DEEP PACKET INSPECTION', type: 'matrix'),
    AppScreenMeta(title: 'Dynamic Multipath Failover Stream', badge: 'SUB-MILLISECOND PIVOT', type: 'table'),
    AppScreenMeta(title: 'Tunnel Encryption & Key Rotation', badge: 'CHACHA20-POLY1305', type: 'config'),
  ],
  'ikaria': [
    AppScreenMeta(title: 'Interactive Skill Vector Radar', badge: 'MULTIMODAL PROFILE', type: 'chart'),
    AppScreenMeta(title: 'Autonomous Opportunity Match Flow', badge: 'DIRECT AGENT CONTACT', type: 'flow'),
    AppScreenMeta(title: 'Verified Code & Project Artifacts', badge: 'PROOF OF WORK', type: 'matrix'),
    AppScreenMeta(title: 'Interview Simulation & Feedback HUD', badge: 'AI PEER REVIEW', type: 'table'),
    AppScreenMeta(title: 'Identity Privacy & Credential Vault', badge: 'ANONYMIZED DISCOVERY', type: 'config'),
  ],
  'orthrozanclus': [
    AppScreenMeta(title: 'Vulnerability Vector Attack Surface', badge: 'CVE & ZERO-DAY SCAN', type: 'chart'),
    AppScreenMeta(title: 'Automated Penetration Test DAG', badge: 'RED-TEAM AGENTS', type: 'flow'),
    AppScreenMeta(title: 'Port & Service Anomaly Detection', badge: 'DEEP NETWORK PROBE', type: 'matrix'),
    AppScreenMeta(title: 'Compliance Audit & ISO Verification', badge: 'SOC2 / HIPAA CERT', type: 'table'),
    AppScreenMeta(title: 'Remediation Script Orchestrator', badge: 'AUTOMATED HOTFIXING', type: 'config'),
  ],
  'tridrishti': [
    AppScreenMeta(title: 'Dense 3D Point Cloud Spatial View', badge: 'REAL-TIME VOXEL MESH', type: 'chart'),
    AppScreenMeta(title: 'Stereo Depth Estimation Pipeline', badge: 'SUB-PIXEL DISPARITY', type: 'flow'),
    AppScreenMeta(title: 'LiDAR & Photogrammetry Alignment', badge: 'SENSOR FUSION 60FPS', type: 'matrix'),
    AppScreenMeta(title: 'Spatial Anchor Coordinate Ledger', badge: 'SLAM RE-LOCALIZATION', type: 'table'),
    AppScreenMeta(title: 'Camera Calibration & Epipolar Config', badge: 'SUB-MILLIMETER CAL', type: 'config'),
  ],
  'opabinia': [
    AppScreenMeta(title: '4K HDR Adaptive Bitrate Stream HUD', badge: 'AV1 / H.265 CODEC', type: 'chart'),
    AppScreenMeta(title: 'Low-Latency Transcoding Pipeline', badge: 'HARDWARE ACCEL NVENC', type: 'flow'),
    AppScreenMeta(title: 'P2P Bandwidth Distribution Mesh', badge: 'EDGE CACHE CLUSTER', type: 'matrix'),
    AppScreenMeta(title: 'DRM Cryptographic Key Delivery', badge: 'WIDEVINE L1 SECURE', type: 'table'),
    AppScreenMeta(title: 'Audio Track & Subtitle Multiplexer', badge: 'MULTI-AUDIO SYNC', type: 'config'),
  ],
  'glycocalyx': [
    AppScreenMeta(title: 'FIDO2 / WebAuthn Hardware Auth HUD', badge: 'PASSKEYS & SECURE ENCLAVE', type: 'chart'),
    AppScreenMeta(title: 'Session Trust Score & Risk Engine', badge: 'ZERO-TRUST EVALUATION', type: 'flow'),
    AppScreenMeta(title: 'Federated Token & JWT Authorization', badge: 'OAUTH 2.1 / OIDC', type: 'matrix'),
    AppScreenMeta(title: 'Biometric Audit & Access Logs', badge: 'CRYPTOGRAPHIC TRAIL', type: 'table'),
    AppScreenMeta(title: 'Identity Provider & Domain Federation', badge: 'MULTI-TENANT REALM', type: 'config'),
  ],
  'cardiodictyon': [
    AppScreenMeta(title: 'Global Node Health & Latency Map', badge: '140+ EDGE NODES', type: 'chart'),
    AppScreenMeta(title: 'Real-Time Telemetry Ring-Buffer Bus', badge: 'NATS JETSTREAM BUS', type: 'flow'),
    AppScreenMeta(title: 'Distributed Consensus & Heartbeat Monitor', badge: 'RAFT PROTOCOL', type: 'matrix'),
    AppScreenMeta(title: 'Cluster Memory & Storage Allocation', badge: 'ZERO-COST INFRA GUARD', type: 'table'),
    AppScreenMeta(title: 'Failover Trigger & Hot Spare Switch', badge: 'AUTOMATED RECOVERY', type: 'config'),
  ],
  'yorgia': [
    AppScreenMeta(title: 'Local LLM Conversational Interface', badge: '100% OFFLINE INFERENCE', type: 'chart'),
    AppScreenMeta(title: 'Semantic Memory & Context Graph', badge: 'EPISODIC RECALL', type: 'flow'),
    AppScreenMeta(title: 'Document RAG & Vector Indexing', badge: 'ON-DEVICE EMBEDDINGS', type: 'matrix'),
    AppScreenMeta(title: 'Local Execution Sandbox & Tools', badge: 'SECURE CODE EXECUTION', type: 'table'),
    AppScreenMeta(title: 'Model Weights & Quantization Settings', badge: 'GGUF Q4_K_M ENGINE', type: 'config'),
  ],
  'spark': [
    AppScreenMeta(title: 'Micro-Agent Interactive Terminal', badge: 'HOT-RELOAD ENGINE', type: 'chart'),
    AppScreenMeta(title: 'Modular Workflow Automation Canvas', badge: 'DRAG & DROP PIPELINES', type: 'flow'),
    AppScreenMeta(title: 'Real-Time Event Stream Inspector', badge: 'SUB-MILLISECOND REACT', type: 'matrix'),
    AppScreenMeta(title: 'Script Performance & CPU Telemetry', badge: 'MEMORY-BOUND GUARD', type: 'table'),
    AppScreenMeta(title: 'Plugin Catalog & Community Registry', badge: 'SANDBOX ISOLATION', type: 'config'),
  ],
  'wiwaxia': [
    AppScreenMeta(title: 'Multi-Repo Code Knowledge Graph', badge: 'CYPHER QUERY ENGINE', type: 'chart'),
    AppScreenMeta(title: 'AST Modification & Refactoring Flow', badge: 'SEMANTIC CODE REWRITE', type: 'flow'),
    AppScreenMeta(title: 'Function Inbound/Outbound Call Trace', badge: 'DEEP DEPENDENCY GRAPH', type: 'matrix'),
    AppScreenMeta(title: 'Code Smell & Lint Anomaly Ledger', badge: 'AUTOMATED AUDIT', type: 'table'),
    AppScreenMeta(title: 'Index Status & Git Hook Sync', badge: 'INCREMENTAL WATCHER', type: 'config'),
  ],
  'spriggina': [
    AppScreenMeta(title: 'Multi-Sensor Real-Time Stream HUD', badge: 'TEMPERATURE / HUMIDITY / CO2', type: 'chart'),
    AppScreenMeta(title: 'Anomaly Detection FFT Waveforms', badge: 'PREDICTIVE ALGORITHMS', type: 'flow'),
    AppScreenMeta(title: 'Spatial Sensor Heatmap Calibration', badge: 'MULTI-ZONE TELEMETRY', type: 'matrix'),
    AppScreenMeta(title: 'Historical Sensor Time-Series Log', badge: 'COMPRESSED CHRONO STORE', type: 'table'),
    AppScreenMeta(title: 'Sensor Calibration & Threshold Alerts', badge: 'INSTANT NOTIFICATIONS', type: 'config'),
  ],
  'cursus': [
    AppScreenMeta(title: 'Spaced Repetition Active Flashcard Deck', badge: 'SM-2 ALGORITHM', type: 'chart'),
    AppScreenMeta(title: 'Interactive Mastery Knowledge Graph', badge: 'CONCEPT HIERARCHY', type: 'flow'),
    AppScreenMeta(title: 'Daily Retention Rate & Memory Curve', badge: 'RETENTION > 94%', type: 'matrix'),
    AppScreenMeta(title: 'Topic Quiz & Challenge Matrix', badge: 'ADAPTIVE DIFFICULTY', type: 'table'),
    AppScreenMeta(title: 'Deck Import & Markdown Sync', badge: 'OBSIDIAN VAULT SYNC', type: 'config'),
  ],
  'tribrachidium': [
    AppScreenMeta(title: 'Multi-Peer CRDT Consensus Stream', badge: 'ZERO CONFLICTS', type: 'chart'),
    AppScreenMeta(title: 'Delta State Vector Replication Flow', badge: 'CAUSAL GRAPH ORDERING', type: 'flow'),
    AppScreenMeta(title: 'Peer Latency & Gossip Network Topology', badge: 'OPTIMAL PEER MESH', type: 'matrix'),
    AppScreenMeta(title: 'Sync Conflict Resolution History', badge: 'DETERMINISTIC MERGE', type: 'table'),
    AppScreenMeta(title: 'Cluster Node Authentication & Keys', badge: 'TLS 1.3 PINNED MESH', type: 'config'),
  ],
  'charnia': [
    AppScreenMeta(title: 'Cryptographic Hash Tree Vault', badge: 'MERKLE INTEGRITY', type: 'chart'),
    AppScreenMeta(title: 'Content-Addressed Chunking Stream', badge: 'DEDUPLICATION 78%', type: 'flow'),
    AppScreenMeta(title: 'Storage Node Geographic Distribution', badge: 'REPLICATION FACTOR 3X', type: 'matrix'),
    AppScreenMeta(title: 'Access Audit Log & Encryption Keys', badge: 'IMMUTABLE AUDIT', type: 'table'),
    AppScreenMeta(title: 'S3-Compatible Gateway Configuration', badge: 'HIGH-AVAILABILITY', type: 'config'),
  ],
  'microdictyon': [
    AppScreenMeta(title: 'Encrypted P2P Mesh Channel Matrix', badge: 'DOUBLE RATCHET PROTOCOL', type: 'chart'),
    AppScreenMeta(title: 'Ephemeral Message Lifespan HUD', badge: 'ZERO-TRACE AUTO-PURGE', type: 'flow'),
    AppScreenMeta(title: 'Decentralized Peer Discovery Radar', badge: 'DHT / MDNS DISCOVERY', type: 'matrix'),
    AppScreenMeta(title: 'Key Fingerprint Verification Ledger', badge: 'SAFETY NUMBER VERIFIED', type: 'table'),
    AppScreenMeta(title: 'Mesh Routing & Relay Hop Settings', badge: 'ONION PACKET ROUTING', type: 'config'),
  ],
  'cloudina': [
    AppScreenMeta(title: 'Micro-VM Container Fleet Telemetry', badge: '4 OCPU / 24GB COMPLIANT', type: 'chart'),
    AppScreenMeta(title: 'Pod Lifecycle & Health Orchestration', badge: 'SUB-100MS COLD START', type: 'flow'),
    AppScreenMeta(title: 'Zero-Cost Infrastructure Budget Gauge', badge: 'STRICT \$0.00 GUARANTEE', type: 'matrix'),
    AppScreenMeta(title: 'Container Log Aggregator & Parser', badge: 'LIVE STDOUT STREAM', type: 'table'),
    AppScreenMeta(title: 'Container Registry & Image Signatures', badge: 'COSMIGN SIGNED', type: 'config'),
  ],
  'hallucigenia': [
    AppScreenMeta(title: 'Real-Time GLSL Generative Canvas', badge: '60FPS PROCEDURAL', type: 'chart'),
    AppScreenMeta(title: 'Latent Space Vector Exploration Flow', badge: 'DIFFUSION MATRIX', type: 'flow'),
    AppScreenMeta(title: 'High-Resolution Render Queue', badge: 'MULTI-GPU ACCELERATED', type: 'matrix'),
    AppScreenMeta(title: 'Aesthetic Prompt & Seed Preset Ledger', badge: 'DETERMINISTIC OUTPUT', type: 'table'),
    AppScreenMeta(title: 'Shader Compilation & Pipeline Setup', badge: 'VULKAN / METAL', type: 'config'),
  ],
  'dropship': [
    AppScreenMeta(title: 'Local Network Discovery Radar', badge: 'PEER-TO-PEER DIRECT', type: 'chart'),
    AppScreenMeta(title: 'High-Speed Cryptographic Transfer Stream', badge: 'UP TO 120 MB/S', type: 'flow'),
    AppScreenMeta(title: 'Transfer Batch Queue & Progress', badge: 'MULTI-FILE STREAM', type: 'matrix'),
    AppScreenMeta(title: 'Cryptographic Delivery Receipt Log', badge: 'SHA-256 VERIFIED', type: 'table'),
    AppScreenMeta(title: 'Device Visibility & Pairing Keys', badge: 'ZERO-CONFIG TLS', type: 'config'),
  ],
  'medical': [
    AppScreenMeta(title: 'Biomarker Screening & Genomic Match', badge: '25K+ GENE TARGETS', type: 'chart'),
    AppScreenMeta(title: 'Clinical Trial Protocol Navigator', badge: 'PHASE 1-4 DATABASE', type: 'flow'),
    AppScreenMeta(title: 'Patient Cohort Stratification Matrix', badge: 'STATISTICAL RIGOR', type: 'matrix'),
    AppScreenMeta(title: 'FDA Adverse Event Surveillance Stream', badge: 'REAL-TIME SAFETY', type: 'table'),
    AppScreenMeta(title: 'Medical Ontology & EMR Integration', badge: 'FHIR / HL7 COMPLIANT', type: 'config'),
  ],
  'trilobite': [
    AppScreenMeta(title: 'Kernel Syscall Stream & Threat HUD', badge: 'EBPF PROBES ACTIVE', type: 'chart'),
    AppScreenMeta(title: 'Process Sandbox & Capability Tree', badge: 'SECCOMP ISOLATION', type: 'flow'),
    AppScreenMeta(title: 'Zero-Day Memory Anomaly Detector', badge: 'HEURISTIC ANALYSIS', type: 'matrix'),
    AppScreenMeta(title: 'Threat Quarantine & Incident Ledger', badge: 'INSTANT ISOLATION', type: 'table'),
    AppScreenMeta(title: 'Security Policy Enforcement Rules', badge: 'HARDENED PROFILE', type: 'config'),
  ],
  'parvancorina': [
    AppScreenMeta(title: 'HNSW Vector Index Distribution HUD', badge: '1536-D EMBEDDINGS', type: 'chart'),
    AppScreenMeta(title: 'Cosine & Dot-Product Distance Query', badge: 'SUB-5MS RECALL', type: 'flow'),
    AppScreenMeta(title: 'Vector Quantization & Memory Gauge', badge: 'SQ8 COMPRESSION', type: 'matrix'),
    AppScreenMeta(title: 'Collection Metadata & Snapshot History', badge: 'DURABLE PERSISTENCE', type: 'table'),
    AppScreenMeta(title: 'SIMD Acceleration & Thread Pool', badge: 'AVX-512 / NEON ACCEL', type: 'config'),
  ],
  'mitochondria': [
    AppScreenMeta(title: 'Live Order Book & Multi-Broker HUD', badge: 'REAL-TIME L2 DEPTH', type: 'chart'),
    AppScreenMeta(title: 'Multi-Market Strategy Screener', badge: 'NSE/BSE/NYSE/FOREX', type: 'matrix'),
    AppScreenMeta(title: 'Autonomous Trade Execution Flow', badge: 'LATENCY < 1MS', type: 'flow'),
    AppScreenMeta(title: 'Historical Backtest & PnL Ledger', badge: 'VERIFIED RETURNS', type: 'table'),
    AppScreenMeta(title: 'Risk Management & MT5 Relay Config', badge: 'SECURE BRIDGE', type: 'config'),
  ],
  'meeseeks': [
    AppScreenMeta(title: 'Agent Swarm Active DAG HUD', badge: '42 AGENTS ACTIVE', type: 'chart'),
    AppScreenMeta(title: 'Task Execution DAG & Workflow', badge: 'PARALLEL PIPELINES', type: 'flow'),
    AppScreenMeta(title: 'On-Device Inference Telemetry', badge: 'OLLAMA / LLAMA.CPP', type: 'matrix'),
    AppScreenMeta(title: 'Agent Memory & Semantic Knowledge', badge: 'QDRANT VECTOR STORE', type: 'table'),
    AppScreenMeta(title: 'Consensus & Governance Guardrails', badge: 'ZERO-DRIFT PROTOCOL', type: 'config'),
  ],
  'kimberella': [
    AppScreenMeta(title: 'Unified Wealth & Asset Overview', badge: 'AGGREGATED BALANCE', type: 'chart'),
    AppScreenMeta(title: 'Vector Transaction Semantic Search', badge: 'NLP TRANSACTION ENGINE', type: 'flow'),
    AppScreenMeta(title: 'RAG Statement Extractor & Audit', badge: 'PDF/CSV PARSER', type: 'matrix'),
    AppScreenMeta(title: 'UPI & Contact Entity Resolution', badge: 'SMART RECONCILIATION', type: 'table'),
    AppScreenMeta(title: 'Encrypted Local SQLite Vault', badge: 'AES-256 ZERO-KNOWLEDGE', type: 'config'),
  ],
};

List<AppScreenMeta> getAppScreens(String slug, String category, String appName) {
  final cleanSlug = slug.toLowerCase().trim();
  if (kEcosystemAppScreens.containsKey(cleanSlug)) {
    return kEcosystemAppScreens[cleanSlug]!;
  }

  // Category-tailored dynamic fallback
  final cat = category.toLowerCase();
  if (cat.contains('health') || cat.contains('medic')) {
    return [
      AppScreenMeta(title: '$appName Patient Health Vitals HUD', badge: 'LIVE BIOMETRICS', type: 'chart'),
      AppScreenMeta(title: 'Encrypted Diagnostic Records Stream', badge: 'HIPAA COMPLIANT', type: 'flow'),
      AppScreenMeta(title: 'Clinical Consultation Telemetry', badge: 'SECURE WEBRTC', type: 'matrix'),
      AppScreenMeta(title: 'Prescription & Pharmacy Ledger', badge: 'VERIFIED RX', type: 'table'),
      AppScreenMeta(title: 'Biometric Sensor Calibration', badge: 'BLE INTERFACE', type: 'config'),
    ];
  } else if (cat.contains('financ') || cat.contains('trad') || cat.contains('money')) {
    return [
      AppScreenMeta(title: '$appName Real-Time Market Orderbook', badge: 'TICK STREAM', type: 'chart'),
      AppScreenMeta(title: 'Execution Routing & Algorithmic Flow', badge: 'SUB-MS FILL', type: 'flow'),
      AppScreenMeta(title: 'Portfolio Multi-Asset Allocation', badge: 'DYNAMIC HEDGE', type: 'matrix'),
      AppScreenMeta(title: 'Historical Audit & PnL Ledger', badge: 'VERIFIED RETURNS', type: 'table'),
      AppScreenMeta(title: 'Risk Guard & Circuit Breaker Setup', badge: 'SAFETY LIMITS', type: 'config'),
    ];
  } else if (cat.contains('secur') || cat.contains('auth')) {
    return [
      AppScreenMeta(title: '$appName Zero-Trust Defense Surface', badge: 'EBPF MONITOR', type: 'chart'),
      AppScreenMeta(title: 'Cryptographic Handshake & Key Exchange', badge: 'CHACHA20-POLY1305', type: 'flow'),
      AppScreenMeta(title: 'Threat Vector Anomaly Detection', badge: 'REAL-TIME PROBE', type: 'matrix'),
      AppScreenMeta(title: 'Access Audit & Provenance Ledger', badge: 'IMMUTABLE TRAIL', type: 'table'),
      AppScreenMeta(title: 'Hardware Token & Passkey Vault', badge: 'FIDO2 / ENCLAVE', type: 'config'),
    ];
  } else if (cat.contains('ai') || cat.contains('intellig')) {
    return [
      AppScreenMeta(title: '$appName Neural Agent Topology HUD', badge: 'ON-DEVICE INFERENCE', type: 'chart'),
      AppScreenMeta(title: 'Execution DAG & Tool Retrieval Pipeline', badge: 'SUB-10MS LATENCY', type: 'flow'),
      AppScreenMeta(title: 'Vector Embedding & Memory Matrix', badge: 'HNSW INDEX', type: 'matrix'),
      AppScreenMeta(title: 'Inference Benchmark & Token Ledger', badge: 'ZERO-DRIFT LOG', type: 'table'),
      AppScreenMeta(title: 'Model Weights & Quantization Setup', badge: 'GGUF / COREML', type: 'config'),
    ];
  }

  // Default Sovereign Infortts App
  return [
    AppScreenMeta(title: '$appName Sovereign Node Dashboard', badge: 'ACTIVE CLUSTER', type: 'chart'),
    AppScreenMeta(title: 'Real-Time Event Stream & Reactive Bus', badge: 'HIGH THROUGHPUT', type: 'flow'),
    AppScreenMeta(title: 'Distributed State & Memory Matrix', badge: 'CONSENSUS OK', type: 'matrix'),
    AppScreenMeta(title: 'Cryptographic Audit & Integrity Log', badge: 'SHA-256 SIGNED', type: 'table'),
    AppScreenMeta(title: 'Fleet Configuration & Node Parameters', badge: 'SECURE PARAMETERS', type: 'config'),
  ];
}
