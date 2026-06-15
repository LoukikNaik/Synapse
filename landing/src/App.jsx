import { useEffect, useRef } from "react";

function useReveal() {
  const ref = useRef(null);
  useEffect(() => {
    const el = ref.current;
    if (!el || typeof IntersectionObserver === "undefined") return;
    const io = new IntersectionObserver(
      (entries) => {
        for (const e of entries) {
          if (e.isIntersecting) {
            e.target.classList.add("in");
            io.unobserve(e.target);
          }
        }
      },
      { rootMargin: "-10% 0px" },
    );
    el.querySelectorAll(".reveal").forEach((n) => io.observe(n));
    return () => io.disconnect();
  }, []);
  return ref;
}

const Phone = ({ src, alt, tilt }) => (
  <div className={`phone ${tilt ? `tilt-${tilt}` : ""}`}>
    <div className="phone-screen">
      <img src={src} alt={alt} loading="lazy" />
    </div>
  </div>
);

export default function App() {
  const rootRef = useReveal();
  return (
    <div ref={rootRef}>
      <Nav />
      <Hero />
      <Stats />
      <Phones />
      <HowItWorks />
      <PromptSection />
      <Stack />
      <CTA />
      <Footer />
    </div>
  );
}

function Nav() {
  return (
    <header className="nav">
      <div className="nav-inner">
        <a href="#top" className="brand">
          <img src="/app_icon.png" alt="Synapse icon" className="brand-mark" />
          <span className="brand-name">Synapse</span>
        </a>
        <div className="nav-actions">
          <a
            className="btn btn-secondary"
            href="https://github.com/LoukikNaik/Synapse"
            target="_blank"
            rel="noreferrer"
          >
            GitHub
          </a>
          <a className="btn btn-primary" href="#how">
            How it works
          </a>
        </div>
      </div>
    </header>
  );
}

function Hero() {
  return (
    <section className="hero" id="top">
      <div className="container">
        <span className="hero-badge reveal">
          <span className="dot" />
          iOS · offline-first · open source
        </span>
        <h1 className="hero-h1 reveal">
          Spaced repetition for <span className="accent">judgment</span>.
          Not just recall.
        </h1>
        <p className="hero-lede reveal">
          Most flashcard apps test trivia. Synapse tests the kind of intuition
          you build over years of design reviews and incident calls.
          Scenario-based cards. Real tradeoffs. SM-2 scheduling tuned for
          decision-making. Turn any book, video, or topic into a deck via an
          LLM prompt.
        </p>
        <div className="hero-ctas reveal">
          <a className="btn btn-primary" href="#how">
            See it in action
          </a>
          <a
            className="btn btn-secondary"
            href="https://github.com/LoukikNaik/Synapse"
            target="_blank"
            rel="noreferrer"
          >
            View source
          </a>
        </div>
        <p className="hero-foot reveal">
          Ships with 220+ scenarios across distributed systems, ML, product, and more
        </p>
      </div>
    </section>
  );
}

function Stats() {
  const items = [
    ["220+", "scenarios shipped"],
    ["SM-2", "scheduling tuned"],
    ["100%", "offline-first"],
    ["1 min", "to spin a new deck"],
  ];
  return (
    <section className="stats">
      <div className="container">
        <div className="stats-grid reveal">
          {items.map(([n, l]) => (
            <div key={l} className="stat">
              <div className="stat-num">{n}</div>
              <div className="stat-label">{l}</div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

function Phones() {
  return (
    <section className="section" id="how">
      <div className="container">
        <div className="section-head">
          <span className="eyebrow">A study session</span>
          <h2 className="section-h2 reveal">
            Five screens. <span className="accent">No trivia.</span>
          </h2>
          <p className="section-lede reveal">
            What you actually see when you open the app. Real iOS screenshots,
            not mockups.
          </p>
        </div>
        <div className="phones reveal">
          <Phone
            src="/screenshots/01_dashboard.png"
            alt="Dashboard with mastery ring and streak"
            tilt="l"
          />
          <Phone
            src="/screenshots/03_study.png"
            alt="A scenario card asking you to pick a multi-leader topology"
          />
          <Phone
            src="/screenshots/05_feedback.png"
            alt="Feedback breakdown with reasoning, tradeoffs, and the common mistake"
            tilt="r"
          />
        </div>
        <p className="phone-cap reveal" style={{ marginTop: "2.5rem" }}>
          Dashboard · Scenario · Feedback
        </p>
      </div>
    </section>
  );
}

function HowItWorks() {
  const steps = [
    {
      n: "01",
      tag: "Pick a deck",
      title: "Your library, your topics",
      body:
        "Every deck shows scenario count, concepts covered, and your per-concept mastery. Hit Study This Deck to focus on a single topic, or Start Study Session to mix everything that's due.",
      chip: "Mastery rings · per-concept progress",
      img: "/screenshots/04_deck_detail.png",
      alt: "Deck detail screen showing concepts and mastery breakdown",
    },
    {
      n: "02",
      tag: "Face a decision",
      title: "Scenario, context, constraints",
      body:
        "Each card is a realistic situation. No multiple-choice trivia. You pick the option you'd actually choose in practice, rate your confidence, and commit. Three options each. One right, two plausible.",
      chip: "Decision-type cards · confidence rating",
      img: "/screenshots/03_study.png",
      alt: "Scenario card with a multi-leader replication topology question",
    },
    {
      n: "03",
      tag: "Learn from the miss",
      title: "Reasoning, tradeoffs, common mistake",
      body:
        "Wrong answers are where the learning happens. You get the reasoning, when the other options would actually be valid, the one takeaway to remember, and the common mistake people make. The card returns sooner.",
      chip: "SM-2 scheduling adapts per-card",
      img: "/screenshots/05_feedback.png",
      alt: "Feedback screen with reasoning, tradeoff analysis, and key takeaway",
    },
  ];
  return (
    <section className="section-tight" id="flow">
      <div className="container">
        <div className="section-head">
          <span className="eyebrow">How it works</span>
          <h2 className="section-h2 reveal">
            Three steps. <span className="accent">Every card.</span>
          </h2>
        </div>
        <div className="steps">
          {steps.map((s, i) => (
            <div
              key={s.n}
              className={`step-card reveal ${i % 2 === 1 ? "reverse" : ""}`}
            >
              <div>
                <div className="step-tag-row">
                  <span className="step-n">{s.n}</span>
                  <span className="step-tag">{s.tag}</span>
                </div>
                <h3 className="step-h3">{s.title}</h3>
                <p className="step-body">{s.body}</p>
                <div className="step-chip">{s.chip}</div>
              </div>
              <div className="step-visual">
                <Phone src={s.img} alt={s.alt} />
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

function PromptSection() {
  return (
    <section className="section-tight" id="prompt">
      <div className="container">
        <div className="section-head">
          <span className="eyebrow">Turn anything into a deck</span>
          <h2 className="section-h2 reveal">
            One <span className="accent">LLM prompt</span>. Any topic.
          </h2>
          <p className="section-lede reveal">
            Watched a video on Kafka internals? Read a chapter of DDIA? Finished
            a guide on React hooks? Paste your source into ChatGPT or Claude with
            the prompt below, paste the JSON into the Import tab, study.
          </p>
        </div>
        <pre className="prompt reveal">
{`Create a Synapse study deck about `}<span className="s">[YOUR TOPIC HERE]</span>{`.

`}<span className="c">## What Synapse Is</span>{`
A spaced-repetition app that tests engineering judgment through
scenario-based cards. Each card presents a realistic situation, asks
the user to make a decision, then explains the reasoning, tradeoffs,
and common mistakes.

`}<span className="c">## Requirements</span>{`
- 15-25 scenarios covering the topic thoroughly
- 3-6 concepts that group the scenarios into themes
- Every scenario tests a `}<span className="k">DECISION</span>{` or `}<span className="k">TRADEOFF</span>{`, not trivia recall
- Each scenario has exactly 3 options - one correct, two plausible-but-wrong
- Explanations should teach: WHY it's right, what tradeoffs exist,
  what mistake people commonly make

Output a single valid JSON object. See the repo for the schema.`}
        </pre>
      </div>
    </section>
  );
}

function Stack() {
  const cards = [
    {
      tag: "Platform",
      title: "iOS 17+, SwiftUI, SwiftData",
      body:
        "Native iOS using the modern SwiftUI app lifecycle. SwiftData for local persistence so the whole library + history lives on-device.",
    },
    {
      tag: "Scheduling",
      title: "SM-2, tuned for decisions",
      body:
        "Each card tracks how hard it is for you specifically. Right + confident pushes review out by days or weeks. Right but unsure pulls it in. Wrong pulls it in fast.",
    },
    {
      tag: "Persistence",
      title: "Offline-first, Keychain backup",
      body:
        "Decks and study progress survive reinstalls via Keychain backup. No server, no account, no analytics, no tracking.",
    },
    {
      tag: "Content",
      title: "Pluggable decks via LLM prompt",
      body:
        "The deck schema is a small JSON object. Generate as many as you want with any LLM, import via the in-app tab. Ships with 220+ scenarios out of the box.",
    },
  ];
  return (
    <section className="section-tight">
      <div className="container">
        <div className="section-head">
          <span className="eyebrow">Stack</span>
          <h2 className="section-h2 reveal">
            What's <span className="accent">under the hood</span>
          </h2>
        </div>
        <div className="stack-grid">
          {cards.map((c) => (
            <div key={c.title} className="stack-card reveal">
              <span className="eyebrow">{c.tag}</span>
              <h3>{c.title}</h3>
              <p>{c.body}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

function CTA() {
  return (
    <section className="cta">
      <div className="container">
        <div className="cta-inner reveal">
          <h2 className="cta-h2">Build judgment, not just recall.</h2>
          <p className="cta-lede">
            220+ scenarios baked in. SM-2 scheduling waiting for your first
            session. Source on GitHub, built in your iOS simulator with one
            xcodebuild.
          </p>
          <div className="cta-ctas">
            <a
              className="btn btn-dark"
              href="https://github.com/LoukikNaik/Synapse"
              target="_blank"
              rel="noreferrer"
              style={{ background: "white", color: "#5B21B6" }}
            >
              View on GitHub
            </a>
            <a className="btn btn-ghost-white" href="#prompt">
              Make your own deck
            </a>
          </div>
        </div>
      </div>
    </section>
  );
}

function Footer() {
  return (
    <footer className="footer">
      <div className="container footer-inner">
        <div className="brand">
          <img src="/app_icon.png" alt="" className="brand-mark" />
          <span className="brand-name">Synapse</span>
          <span className="footer-by">by Loukik Naik</span>
        </div>
        <div className="footer-links">
          <a href="https://github.com/LoukikNaik/Synapse" target="_blank" rel="noreferrer">
            GitHub
          </a>
          <a href="#how">Flow</a>
          <a href="#prompt">Deck prompt</a>
        </div>
      </div>
    </footer>
  );
}
