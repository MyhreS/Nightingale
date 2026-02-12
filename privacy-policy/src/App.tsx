import "./App.css";

const EFFECTIVE_DATE = "February 12, 2026";
const CONTACT_EMAIL = "simonmyhre1@gmail.com";

type DataItem = { label: string; purpose: string };

const identifiers: DataItem[] = [
  { label: "User ID", purpose: "App Functionality" },
  { label: "Device ID", purpose: "App Functionality" },
];

const usageData: DataItem[] = [
  { label: "Product Interaction", purpose: "Analytics" },
  { label: "Other Usage Data", purpose: "Analytics" },
];

const diagnostics: DataItem[] = [
  { label: "Crash Data", purpose: "Analytics" },
  { label: "Performance Data", purpose: "Analytics" },
];

type DataCardProps = {
  title: string;
  items: DataItem[];
};

const DataCard = ({ title, items }: DataCardProps) => (
  <div className="data-card">
    <div className="data-card-title">{title}</div>
    {items.map((item) => (
      <div className="data-item" key={item.label}>
        <span className="data-label">{item.label}</span>
        <span className="data-purpose">{item.purpose}</span>
      </div>
    ))}
  </div>
);

const App = () => {
  return (
    <div className="page">
      <header className="header">
        <div className="app-name">PuckBeats</div>
        <h1 className="title">Privacy Policy</h1>
        <p className="effective-date">Effective {EFFECTIVE_DATE}</p>
      </header>

      <section className="section">
        <h2 className="section-title">Overview</h2>
        <p>
          PuckBeats is a music app that streams curated hockey-themed playlists powered by SoundCloud. We respect your privacy and are committed to
          being transparent about the data we collect and how it is used.
        </p>
      </section>

      <section className="section">
        <h2 className="section-title">Data Not Linked to You</h2>
        <p>
          The following data may be collected but it is not linked to your identity. None of the data we collect can be used to personally identify
          you.
        </p>
      </section>

      <section className="section">
        <h2 className="section-title">Data We Collect</h2>
        <p>We collect 6 data types across three categories:</p>

        <DataCard title="Identifiers" items={identifiers} />
        <DataCard title="Usage Data" items={usageData} />
        <DataCard title="Diagnostics" items={diagnostics} />
      </section>

      <section className="section">
        <h2 className="section-title">How We Use Your Data</h2>
        <ul>
          <li>
            <strong>App Functionality:</strong> User ID and Device ID are used solely to provide core app features such as authentication and
            personalized playback.
          </li>
          <li>
            <strong>Analytics:</strong> Product interaction, usage data, crash data, and performance data help us understand how the app is used and
            improve its stability and performance.
          </li>
        </ul>
      </section>

      <section className="section">
        <h2 className="section-title">Third-Party Services</h2>
        <p>PuckBeats uses the following third-party services:</p>
        <ul>
          <li>
            <strong>SoundCloud</strong> for music streaming and authentication. Your SoundCloud profile information (such as your display name) is
            accessed locally on your device for display purposes only and is not stored on our servers. Your playback activity is subject to
            SoundCloud's own privacy policy.
          </li>
          <li>
            <strong>Firebase (Google)</strong> for authentication, analytics, and storing the song catalog fetched on app startup. Firebase may
            collect device identifiers, crash logs, and performance metrics.
          </li>
        </ul>
      </section>

      <section className="section">
        <h2 className="section-title">Data Sharing</h2>
        <p>
          We do not sell, trade, or rent your personal information to third parties. Data is only shared with the third-party service providers listed
          above as necessary to operate the app.
        </p>
      </section>

      <section className="section">
        <h2 className="section-title">Data Retention</h2>
        <p>
          Analytics and diagnostic data is retained only for as long as necessary to fulfill the purposes described in this policy. You can request
          deletion of your data at any time by contacting us.
        </p>
      </section>

      <section className="section">
        <h2 className="section-title">Children's Privacy</h2>
        <p>
          PuckBeats does not knowingly collect personal information from children under the age of 13. If you believe we have inadvertently collected
          such information, please contact us so we can promptly delete it.
        </p>
      </section>

      <section className="section">
        <h2 className="section-title">Changes to This Policy</h2>
        <p>
          We may update this privacy policy from time to time. Any changes will be posted on this page with an updated effective date. We encourage
          you to review this policy periodically.
        </p>
      </section>

      <section className="section">
        <h2 className="section-title">Contact Us</h2>
        <p>
          If you have any questions or concerns about this privacy policy, please contact us at{" "}
          <a href={`mailto:${CONTACT_EMAIL}`}>{CONTACT_EMAIL}</a>.
        </p>
      </section>

      <div className="divider" />

      <footer className="footer">
        <p>&copy; {new Date().getFullYear()} PuckBeats. All rights reserved.</p>
      </footer>
    </div>
  );
};

export default App;
