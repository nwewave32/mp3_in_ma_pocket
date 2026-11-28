/// The app's path on the legal site, e.g. "ipkong" for
/// https://ireuisu-legal.vercel.app/ipkong/privacy/.
const String legalSlug = 'pocket-mp3';

/// The privacy policy page for [slug], or null without one.
Uri? privacyPolicyUrl([String? slug = legalSlug]) =>
    slug == null ? null : Uri.https('ireuisu-legal.vercel.app', '/$slug/privacy/');
