import React from 'react';
import type { CSSProperties, ReactNode } from 'react';

/* ═══════════════════════════════════════════════════════════════════════════
   OpenClawps — Infrastructure Lifecycle Diagram

   Single-file React/TypeScript diagram. No external dependencies beyond React.
   Render <ClawOps /> as the sole page content.
   ═══════════════════════════════════════════════════════════════════════════ */

// ─── Palette ────────────────────────────────────────────────────────────────

const P = {
  bg:       '#0a0e1a',
  surface:  '#0f1629',
  card:     '#151d35',
  border:   '#1c2951',
  borderLt: '#253566',

  blue:     '#3b82f6',
  blueDim:  '#1e3a5f',
  cyan:     '#06b6d4',
  cyanDim:  '#0c2d3d',
  green:    '#22c55e',
  greenDim: '#0a2e1a',
  amber:    '#f59e0b',
  amberDim: '#3d2800',
  purple:   '#a855f7',
  purpleDim:'#2d1854',
  red:      '#ef4444',
  pink:     '#ec4899',
  pinkDim:  '#3b1131',

  text:     '#e2e8f0',
  textSec:  '#94a3b8',
  textMut:  '#64748b',
} as const;

const mono: CSSProperties = {
  fontFamily: "'JetBrains Mono','Fira Code','SF Mono',Consolas,monospace",
};

// ─── Primitives ─────────────────────────────────────────────────────────────

function SectionLabel({ children, color }: { children: ReactNode; color: string }) {
  return (
    <div style={{
      fontSize: 10, fontWeight: 700, letterSpacing: '0.12em',
      textTransform: 'uppercase', color, marginBottom: 20,
    }}>
      {children}
    </div>
  );
}

function HArrow({ color = P.textMut }: { color?: string }) {
  return (
    <svg width="36" height="16" viewBox="0 0 36 16" style={{ flexShrink: 0 }}>
      <line x1="2" y1="8" x2="26" y2="8" stroke={color} strokeWidth="1.5" strokeDasharray="4 3" />
      <polygon points="26,4 34,8 26,12" fill={color} />
    </svg>
  );
}

function VArrow({ color = P.textMut }: { color?: string }) {
  return (
    <div style={{ display: 'flex', justifyContent: 'center', padding: '6px 0' }}>
      <svg width="16" height="28" viewBox="0 0 16 28">
        <line x1="8" y1="2" x2="8" y2="20" stroke={color} strokeWidth="1.5" strokeDasharray="4 3" />
        <polygon points="4,20 8,28 12,20" fill={color} />
      </svg>
    </div>
  );
}

function Tag({ children, bg, fg, style: extra }: { children: ReactNode; bg: string; fg: string; style?: CSSProperties }) {
  return (
    <span style={{
      display: 'inline-flex', alignItems: 'center', gap: 4,
      padding: '2px 8px', borderRadius: 4, fontSize: 11, fontWeight: 600,
      background: bg, color: fg, whiteSpace: 'nowrap', ...mono, ...extra,
    }}>
      {children}
    </span>
  );
}

function Dot({ color, size = 8 }: { color: string; size?: number }) {
  return <span style={{ display: 'inline-block', width: size, height: size, borderRadius: '50%', background: color, flexShrink: 0 }} />;
}

/** Nested architecture box with floating label */
function Layer({ label, color, children, style: extra }: {
  label: string; color: string; children: ReactNode; style?: CSSProperties;
}) {
  return (
    <div style={{
      border: `1px solid ${color}35`, borderRadius: 8, padding: '20px 16px 16px',
      background: `${color}08`, position: 'relative', ...extra,
    }}>
      <span style={{
        position: 'absolute', top: -9, left: 12, background: P.surface, padding: '0 8px',
        fontSize: 10, fontWeight: 700, letterSpacing: '0.08em', textTransform: 'uppercase', color,
      }}>
        {label}
      </span>
      {children}
    </div>
  );
}

/** Small inline service box */
function ServiceBox({ name, detail, color, port }: {
  name: string; detail: string; color: string; port?: string;
}) {
  return (
    <div style={{
      background: P.card, border: `1px solid ${color}30`, borderRadius: 6,
      padding: '10px 14px', flex: '1 1 0',
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 4 }}>
        <Dot color={color} />
        <span style={{ fontSize: 13, fontWeight: 600, color: P.text }}>{name}</span>
        {port && <Tag bg={`${P.cyan}20`} fg={P.cyan} style={{ marginLeft: 'auto' }}>:{port}</Tag>}
      </div>
      <div style={{ fontSize: 11, color: P.textSec, lineHeight: 1.4 }}>{detail}</div>
    </div>
  );
}

// ─── Section: Header ────────────────────────────────────────────────────────

function Header() {
  return (
    <header style={{ textAlign: 'center', marginBottom: 48 }}>
      <h1 style={{
        fontSize: 52, fontWeight: 800, margin: 0, letterSpacing: '-0.03em',
        background: `linear-gradient(135deg, ${P.blue}, ${P.cyan}, ${P.purple})`,
        WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent',
        backgroundClip: 'text',
      }}>
        OpenClawps
      </h1>
      <p style={{ fontSize: 12, color: P.textMut, margin: '8px 0 0', ...mono }}>
        Single-VM autonomous agent deployment on Azure — from scratch to production in four phases
      </p>
      <a
        href="https://github.com/logan-robbins/openclawps"
        target="_blank"
        rel="noopener noreferrer"
        style={{ fontSize: 12, color: P.blue, marginTop: 8, display: 'inline-block', ...mono }}
      >
        github.com/logan-robbins/openclawps
      </a>
    </header>
  );
}

// ─── Section: Prerequisites ─────────────────────────────────────────────────

function Prerequisites() {
  const required = [
    { label: 'Azure Account', detail: 'az login — any subscription', envVar: 'az login', color: P.blue },
    { label: 'Telegram Bot Token', detail: '@BotFather /newbot', envVar: 'TELEGRAM_BOT_TOKEN', color: P.cyan },
    { label: 'LLM API Key', detail: 'xAI required, OpenAI optional', envVar: 'XAI_API_KEY', color: P.amber },
  ];
  const optional = [
    { v: 'OPENAI_API_KEY', l: 'OpenAI fallback model' },
    { v: 'BRIGHTDATA_API_TOKEN', l: 'Web scraping' },
    { v: 'TELEGRAM_USER_ID', l: 'DM allowlist' },
    { v: 'VM_PASSWORD', l: 'SSH + VNC' },
  ];

  return (
    <section style={{ background: P.surface, border: `1px solid ${P.border}`, borderRadius: 12, padding: 32, borderTop: `3px solid ${P.amber}` }}>
      <SectionLabel color={P.amber}>Input Artifacts — Prerequisites</SectionLabel>

      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 12, flexWrap: 'wrap' }}>
        {required.map((r, i) => (
          <React.Fragment key={r.envVar}>
            <div style={{
              background: P.card, border: `1px solid ${r.color}30`, borderRadius: 8,
              padding: '16px 20px', minWidth: 190, textAlign: 'center',
            }}>
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6, marginBottom: 6 }}>
                <Dot color={r.color} />
                <span style={{ fontSize: 14, fontWeight: 600, color: P.text }}>{r.label}</span>
              </div>
              <div style={{ fontSize: 11, color: P.textSec, marginBottom: 6 }}>{r.detail}</div>
              <Tag bg={`${r.color}20`} fg={r.color}>{r.envVar}</Tag>
            </div>
            {i < required.length - 1 && <HArrow color={P.amber} />}
          </React.Fragment>
        ))}
      </div>

      <VArrow color={P.amber} />

      <div style={{ display: 'flex', justifyContent: 'center' }}>
        <div style={{ background: P.card, border: `1px solid ${P.border}`, borderRadius: 8, padding: '10px 20px', display: 'flex', alignItems: 'center', gap: 10 }}>
          <Tag bg={P.amberDim} fg={P.amber}>.env</Tag>
          <span style={{ fontSize: 12, color: P.textSec }}>envsubst renders cloud-init templates at deploy time</span>
        </div>
      </div>

      <div style={{ marginTop: 14, display: 'flex', gap: 10, flexWrap: 'wrap', justifyContent: 'center', alignItems: 'center' }}>
        <span style={{ fontSize: 10, color: P.textMut, textTransform: 'uppercase', letterSpacing: '0.08em' }}>Optional:</span>
        {optional.map(o => (
          <span key={o.v} style={{ display: 'inline-flex', alignItems: 'center', gap: 4, fontSize: 11, color: P.textMut }}>
            <Tag bg={`${P.textMut}15`} fg={P.textMut}>{o.v}</Tag> {o.l}
          </span>
        ))}
      </div>
    </section>
  );
}

// ─── Section: Lifecycle Pipeline ────────────────────────────────────────────

function Pipeline() {
  const phases = [
    { n: 1, cmd: 'scratch', title: 'Build from Source', desc: 'Stock Ubuntu 24.04, cloud-init full install (~10 min)',
      artifacts: ['vm-runtime/cloud-init/scratch.yaml', 'Node 24 + OpenClaw + Chrome + Claude CLI'], mlops: 'Train from scratch', color: P.blue },
    { n: 2, cmd: 'bake', title: 'Capture Image', desc: 'Generalize VM, push to Azure Compute Gallery',
      artifacts: ['gallery/claw-base/x.y.z', 'waagent deprovision, secrets stripped'], mlops: 'Registry push', color: P.green },
    { n: 3, cmd: '(default)', title: 'Deploy from Image', desc: 'Golden image + fresh data disk per instance',
      artifacts: ['vm-runtime/cloud-init/image.yaml (secrets only)', 'Data disk auto-partitioned + seeded'], mlops: 'Inference deploy', color: P.cyan },
    { n: 4, cmd: 'upgrade', title: 'Upgrade in Place', desc: 'New image version, same data disk — identity preserved',
      artifacts: ['Detach data disk, delete VM, recreate, reattach', 'NIC + public IP reused'], mlops: 'Rolling update', color: P.purple },
  ];

  return (
    <section style={{ background: P.surface, border: `1px solid ${P.border}`, borderRadius: 12, padding: 32, borderTop: `3px solid ${P.blue}` }}>
      <SectionLabel color={P.blue}>Lifecycle Pipeline — deploy.sh [mode]</SectionLabel>

      <div style={{ display: 'flex', flexDirection: 'column', gap: 0, alignItems: 'center' }}>
        {phases.map((p, i) => (
          <React.Fragment key={p.n}>
            <div style={{
              background: P.card, border: `1px solid ${p.color}30`, borderRadius: 8,
              padding: '16px 20px', width: '100%', maxWidth: 600, position: 'relative',
              display: 'flex', gap: 16, alignItems: 'flex-start',
            }}>
              <div style={{
                width: 36, height: 36, borderRadius: '50%', flexShrink: 0,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                background: `${p.color}20`, border: `2px solid ${p.color}`, color: p.color,
                fontSize: 14, fontWeight: 800,
              }}>
                {p.n}
              </div>
              <div style={{ flex: 1 }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 4 }}>
                  <Tag bg={`${p.color}20`} fg={p.color}>deploy.sh {p.cmd}</Tag>
                  <span style={{ fontSize: 14, fontWeight: 700, color: P.text }}>{p.title}</span>
                </div>
                <p style={{ fontSize: 11, color: P.textSec, margin: '0 0 6px', lineHeight: 1.4 }}>{p.desc}</p>
                <div style={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                  {p.artifacts.map((a, j) => (
                    <div key={j} style={{ fontSize: 10, color: P.textMut, ...mono, display: 'flex', gap: 4 }}>
                      <span style={{ color: `${p.color}90` }}>&#x25AA;</span><span>{a}</span>
                    </div>
                  ))}
                </div>
                <div style={{ marginTop: 6, fontSize: 10, color: P.textMut, fontStyle: 'italic' }}>
                  MLOps: {p.mlops}
                </div>
              </div>
            </div>
            {i < phases.length - 1 && <VArrow color={p.color} />}
          </React.Fragment>
        ))}
      </div>

      {/* Cycle callout */}
      <div style={{
        marginTop: 20, display: 'flex', justifyContent: 'center', gap: 12, alignItems: 'center',
        padding: '10px 20px', background: `${P.purple}10`, border: `1px dashed ${P.purple}40`,
        borderRadius: 8,
      }}>
        <svg width="20" height="20" viewBox="0 0 20 20" style={{ flexShrink: 0 }}>
          <path d="M10,2 A8,8 0 1,1 4,6" fill="none" stroke={P.purple} strokeWidth="1.5" />
          <polygon points="2,3 4,7 7,4" fill={P.purple} />
        </svg>
        <span style={{ fontSize: 12, color: P.purple }}>
          <strong>Upgrade cycle:</strong> bake new image version &#x2192; upgrade existing instances &#x2192; data disk preserved across versions
        </span>
      </div>
    </section>
  );
}

// ─── Section: VM Runtime Architecture ───────────────────────────────────────

function Architecture() {
  return (
    <section style={{ background: P.surface, border: `1px solid ${P.border}`, borderRadius: 12, padding: 32, borderTop: `3px solid ${P.green}` }}>
      <SectionLabel color={P.green}>Runtime Topology — Inside a Running Claw</SectionLabel>

      <div style={{ display: 'flex', gap: 20, flexWrap: 'wrap' }}>
        {/* ─── Left: nested architecture ─── */}
        <div style={{ flex: '1 1 640px' }}>
          <Layer label="Azure Resource Group" color={P.blue}>
            <Layer label="VNet 10.0.0.0/16" color={P.cyan} style={{ marginTop: 4 }}>
              <Layer label="Subnet 10.0.0.0/24 + NSG (AllowAll)" color={P.cyan} style={{ marginTop: 4 }}>

                {/* Public IP badge */}
                <div style={{ display: 'flex', gap: 8, alignItems: 'center', marginBottom: 12 }}>
                  <Tag bg={`${P.cyan}20`} fg={P.cyan}>Public IP (Standard SKU)</Tag>
                  <span style={{ fontSize: 11, color: P.textMut }}>Static across stop/start cycles</span>
                </div>

                <Layer label={`VM  Standard_D2s_v3  Ubuntu 24.04`} color={P.green} style={{ marginTop: 4 }}>

                  {/* Display stack */}
                  <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap', marginBottom: 12 }}>
                    <ServiceBox name="lightdm" detail="Auto-login azureuser into xfce4-session on :0" color={P.blue} />
                    <ServiceBox name="x11vnc" detail="Attached to :0, shared + viewonly, password auth" color={P.cyan} port="5900" />
                  </div>
                  <div style={{
                    fontSize: 10, color: P.textMut, ...mono, marginBottom: 14, padding: '4px 10px',
                    background: `${P.blue}08`, borderRadius: 4, border: `1px solid ${P.border}`,
                  }}>
                    Display :0 &mdash; dummy Xorg 1920x1080 &mdash; persists across VNC connect/disconnect &mdash; DPMS disabled
                  </div>

                  {/* OpenClaw Gateway */}
                  <Layer label="OpenClaw Gateway (systemd)" color={P.amber} style={{ marginBottom: 12 }}>
                    <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap', marginBottom: 10 }}>
                      <ServiceBox name="Telegram Channel" detail="Bot API polling, DM policy: allowlist or open" color={P.cyan} />
                      <ServiceBox
                        name='Agent "main"'
                        detail="Model: xai/grok-4 (200k ctx) | Sandbox: off | Max concurrent: 4 | Elevated: full"
                        color={P.amber}
                        port="18789"
                      />
                    </div>
                    <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', marginBottom: 8 }}>
                      {[
                        { l: 'Exec: full autonomy', c: P.red },
                        { l: 'Chrome (CDP, .deb)', c: P.green },
                        { l: 'Web search', c: P.blue },
                        { l: 'Web fetch', c: P.blue },
                      ].map(t => <Tag key={t.l} bg={`${t.c}15`} fg={t.c}>{t.l}</Tag>)}
                    </div>
                    <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
                      {['openclaw.json', 'exec-approvals.json', 'SOUL.md'].map(f => (
                        <span key={f} style={{ fontSize: 10, color: P.textMut, ...mono }}>
                          <span style={{ color: P.amber }}>&#x25AB;</span> {f}
                        </span>
                      ))}
                    </div>
                  </Layer>

                  {/* Claude Code sidecar */}
                  <Layer label="Claude Code Sidecar" color={P.pink} style={{ marginBottom: 12 }}>
                    <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap' }}>
                      <ServiceBox
                        name="tmux session: claude"
                        detail='claude remote-control --name "$(hostname)" | Working dir: ~/workspace'
                        color={P.pink}
                      />
                    </div>
                    <div style={{ fontSize: 10, color: P.textMut, marginTop: 6 }}>
                      Started by /opt/claw/start-claude.sh &mdash; idempotent, skips if session exists
                    </div>
                  </Layer>

                  {/* Storage */}
                  <Layer label="Storage" color={P.purple}>
                    <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap' }}>
                      <div style={{ background: P.card, border: `1px solid ${P.border}`, borderRadius: 6, padding: '10px 14px', flex: '0 1 200px' }}>
                        <div style={{ fontSize: 12, fontWeight: 600, color: P.textSec, marginBottom: 4 }}>OS Disk</div>
                        <div style={{ fontSize: 11, color: P.textMut }}>From gallery image</div>
                        <div style={{ fontSize: 10, color: P.textMut, ...mono, marginTop: 2 }}>Stateless &mdash; replaced on upgrade</div>
                      </div>
                      <div style={{ background: P.card, border: `1px solid ${P.purple}30`, borderRadius: 6, padding: '10px 14px', flex: '1 1 300px' }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 4 }}>
                          <Dot color={P.purple} />
                          <span style={{ fontSize: 12, fontWeight: 600, color: P.text }}>Data Disk /mnt/claw-data</span>
                          <Tag bg={`${P.purple}20`} fg={P.purple}>PERSISTENT</Tag>
                        </div>
                        <div style={{ fontSize: 11, color: P.textSec, marginBottom: 6 }}>
                          Survives upgrades &mdash; detach/reattach preserves agent identity
                        </div>
                        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 4 }}>
                          {[
                            'openclaw/', 'workspace/', '.env', 'SOUL.md',
                            'vnc-password.txt', 'update-version.txt', '.claw-initialized',
                          ].map(f => (
                            <Tag key={f} bg={`${P.purple}12`} fg={P.purple} style={{ fontSize: 10 }}>{f}</Tag>
                          ))}
                        </div>
                        <div style={{ fontSize: 10, color: P.textMut, ...mono, marginTop: 6 }}>
                          Symlinked: ~/.openclaw &#x2192; /mnt/claw-data/openclaw | ~/workspace &#x2192; /mnt/claw-data/workspace
                        </div>
                      </div>
                    </div>
                  </Layer>

                </Layer>
              </Layer>
            </Layer>
          </Layer>
        </div>

        {/* ─── Network & operational details as a two-column table ─── */}
        <div style={{ flex: '1 1 100%' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: 12 }}>
            <tbody>
              {([
                ['Inbound :22', 'SSH (password auth)'],
                ['Inbound :5900', 'VNC (x11vnc, shared + viewonly)'],
                ['Loopback :18789', 'OpenClaw Gateway (not externally exposed)'],
                ['api.x.ai', 'Outbound — LLM inference (xAI / Grok-4)'],
                ['api.telegram.org', 'Outbound — Bot API polling'],
                ['*.google.com', 'Outbound — Chrome / CDP browsing'],
                ['NSG', 'AllowAll (wide open) — ufw disabled'],
                ['sudo', 'NOPASSWD ALL — full autonomy'],
                ['Exec sandbox', <span>off — <span style={{ color: P.red, fontWeight: 600 }}>dev/experiment only</span></span>],
                ['Compute Gallery', <span style={mono}>clawGallery/claw-base/x.y.z</span>],
              ] as [string, ReactNode][]).map(([label, detail]) => (
                <tr key={label}>
                  <td style={{
                    padding: '6px 12px', borderBottom: `1px solid ${P.border}`,
                    color: P.text, fontWeight: 600, whiteSpace: 'nowrap', width: 160, ...mono, fontSize: 11,
                  }}>
                    {label}
                  </td>
                  <td style={{
                    padding: '6px 12px', borderBottom: `1px solid ${P.border}`,
                    color: P.textSec, fontSize: 11,
                  }}>
                    {detail}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </section>
  );
}

// ─── Section: Boot Orchestration ────────────────────────────────────────────

function BootSequence() {
  const steps = [
    { n: 1, label: 'Mount disk', detail: 'LUN 0 discovery, auto-partition if raw, fstab by UUID', color: P.purple },
    { n: 2, label: 'Seed defaults', detail: 'First boot: copy /opt/claw/defaults/ to data disk', color: P.green },
    { n: 3, label: 'Symlinks', detail: '~/.openclaw and ~/workspace point to /mnt/claw-data/', color: P.blue },
    { n: 4, label: 'Permissions', detail: 'chown -R azureuser on data mount and home dir', color: P.blue },
    { n: 5, label: 'VNC sync', detail: 'Data disk password pushed to /etc/x11vnc.pass', color: P.cyan },
    { n: 6, label: 'Run updates', detail: 'Numbered scripts in /opt/claw/updates/ (version-gated)', color: P.amber },
    { n: 7, label: 'Start services', detail: 'lightdm, x11vnc, openclaw-gateway, claude sidecar', color: P.green },
  ];

  return (
    <section style={{ background: P.surface, border: `1px solid ${P.border}`, borderRadius: 12, padding: 32, borderTop: `3px solid ${P.purple}` }}>
      <SectionLabel color={P.purple}>Boot Orchestration — /opt/claw/boot.sh (runs every VM start)</SectionLabel>

      <div style={{ display: 'flex', alignItems: 'flex-start', gap: 0, flexWrap: 'wrap', justifyContent: 'center' }}>
        {steps.map((s, i) => (
          <React.Fragment key={s.n}>
            <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', width: 120, textAlign: 'center' }}>
              <div style={{
                width: 32, height: 32, borderRadius: '50%', display: 'flex', alignItems: 'center', justifyContent: 'center',
                background: `${s.color}20`, border: `2px solid ${s.color}`, color: s.color,
                fontSize: 13, fontWeight: 700, marginBottom: 6,
              }}>
                {s.n}
              </div>
              <div style={{ fontSize: 12, fontWeight: 600, color: P.text, marginBottom: 2 }}>{s.label}</div>
              <div style={{ fontSize: 10, color: P.textMut, lineHeight: 1.3 }}>{s.detail}</div>
            </div>
            {i < steps.length - 1 && (
              <div style={{ display: 'flex', alignItems: 'flex-start', paddingTop: 8 }}>
                <HArrow color={P.textMut} />
              </div>
            )}
          </React.Fragment>
        ))}
      </div>

      {/* Update mechanism detail */}
      <div style={{
        marginTop: 20, display: 'flex', gap: 16, flexWrap: 'wrap', justifyContent: 'center',
      }}>
        <div style={{ background: P.card, border: `1px solid ${P.border}`, borderRadius: 8, padding: '12px 16px', flex: '1 1 300px', maxWidth: 440 }}>
          <div style={{ fontSize: 10, fontWeight: 700, letterSpacing: '0.08em', textTransform: 'uppercase', color: P.amber, marginBottom: 6 }}>
            Update Mechanism — run-updates.sh
          </div>
          <div style={{ fontSize: 11, color: P.textSec, lineHeight: 1.5, ...mono }}>
            /opt/claw/updates/<br />
            &nbsp;&nbsp;001-initial.sh&nbsp;&nbsp;&nbsp;&nbsp;<span style={{ color: P.textMut }}># baseline (no-op)</span><br />
            &nbsp;&nbsp;002-test-marker.sh <span style={{ color: P.textMut }}># example migration</span><br />
            &nbsp;&nbsp;NNN-*.sh&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style={{ color: P.textMut }}># applied in order</span>
          </div>
          <div style={{ fontSize: 10, color: P.textMut, marginTop: 6 }}>
            Version tracked in /mnt/claw-data/update-version.txt. Each script runs once, version advances on success.
          </div>
        </div>
        <div style={{ background: P.card, border: `1px solid ${P.border}`, borderRadius: 8, padding: '12px 16px', flex: '1 1 240px', maxWidth: 340 }}>
          <div style={{ fontSize: 10, fontWeight: 700, letterSpacing: '0.08em', textTransform: 'uppercase', color: P.green, marginBottom: 6 }}>
            Health Validation — verify.sh
          </div>
          <div style={{ fontSize: 11, color: P.textSec, lineHeight: 1.5 }}>
            Runs post-deploy via SSH. Checks:
          </div>
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: 4, marginTop: 4 }}>
            {['Disk mounted', 'Symlinks valid', 'Config JSON valid', 'Services active',
              'Ports listening', 'Binaries found', 'Env vars set'].map(c => (
              <Tag key={c} bg={`${P.green}12`} fg={P.green} style={{ fontSize: 9 }}>{c}</Tag>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}

// ─── Section: MLOps Mapping ─────────────────────────────────────────────────

function OpsMapping() {
  const rows: [string, string, string][] = [
    ['deploy.sh scratch', 'Train from scratch', 'Full environment built from stock Ubuntu'],
    ['deploy.sh bake', 'Registry push', 'Generalized VM captured to Compute Gallery'],
    ['Azure Compute Gallery', 'Model / artifact registry', 'Versioned golden images (claw-base/x.y.z)'],
    ['deploy.sh (default)', 'Inference deployment', 'Spin up instance from image + data disk'],
    ['deploy.sh upgrade', 'Rolling update', 'New image, same persistent state'],
    ['Data Disk', 'Feature store / state', 'Agent identity, workspace, config survive upgrades'],
    ['boot.sh', 'Inference server init', 'Mount, seed, wire, start — every boot'],
    ['run-updates.sh', 'Drift remediation', 'Versioned migration scripts applied in order'],
    ['verify.sh', 'Model validation', 'Post-deploy health checks across all subsystems'],
    ['SOUL.md', 'Model card', 'Agent personality / identity definition'],
    ['.env', 'Secrets management', 'Never committed, injected at deploy via envsubst'],
  ];

  return (
    <section style={{ background: P.surface, border: `1px solid ${P.border}`, borderRadius: 12, padding: 32, borderTop: `3px solid ${P.textMut}` }}>
      <SectionLabel color={P.textMut}>OpenClawps / MLOps Conceptual Mapping</SectionLabel>
      <div style={{ overflowX: 'auto' }}>
        <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: 12 }}>
          <thead>
            <tr>
              {['OpenClawps Concept', 'MLOps Equivalent', 'Notes'].map(h => (
                <th key={h} style={{
                  textAlign: 'left', padding: '6px 12px', borderBottom: `1px solid ${P.border}`,
                  color: P.textMut, fontSize: 10, fontWeight: 700, letterSpacing: '0.08em', textTransform: 'uppercase',
                }}>
                  {h}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {rows.map(([claw, ml, note]) => (
              <tr key={claw}>
                <td style={{ padding: '6px 12px', borderBottom: `1px solid ${P.border}`, color: P.text, ...mono, fontSize: 11 }}>{claw}</td>
                <td style={{ padding: '6px 12px', borderBottom: `1px solid ${P.border}`, color: P.cyan }}>{ml}</td>
                <td style={{ padding: '6px 12px', borderBottom: `1px solid ${P.border}`, color: P.textMut, fontSize: 11 }}>{note}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </section>
  );
}

// ─── Main ───────────────────────────────────────────────────────────────────

export default function ClawOps() {
  return (
    <div style={{
      background: P.bg, minHeight: '100vh', color: P.text,
      fontFamily: "-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,'Helvetica Neue',Arial,sans-serif",
      padding: '48px 24px',
    }}>
      <div style={{ maxWidth: 1100, margin: '0 auto', display: 'flex', flexDirection: 'column', gap: 32 }}>
        <Header />
        <Prerequisites />
        <VArrow color={P.textMut} />
        <Pipeline />
        <VArrow color={P.textMut} />
        <Architecture />
        <VArrow color={P.textMut} />
        <BootSequence />
        <OpsMapping />
        <footer style={{ textAlign: 'center', fontSize: 11, color: P.textMut, padding: '16px 0', ...mono }}>
          OpenClawps
        </footer>
      </div>
    </div>
  );
}
