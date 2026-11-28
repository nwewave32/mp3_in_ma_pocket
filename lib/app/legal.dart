/// The app's path on the legal site, e.g. "ipkong" for
/// https://ireuisu-legal.vercel.app/ipkong/privacy/.
///
/// Null until the App Store name is decided (PRD open item). Until then the
/// Privacy Policy row opens nothing.
const String? legalSlug = null;

/// The privacy policy page for [slug], or null without one.
Uri? privacyPolicyUrl([String? slug = legalSlug]) =>
    slug == null ? null : Uri.https('ireuisu-legal.vercel.app', '/$slug/privacy/');
