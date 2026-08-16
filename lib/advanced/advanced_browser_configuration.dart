/// Optimistic Browser V4 capability and policy layer.
///
/// This file centralizes the 31 requested advanced capabilities and the
/// browser-hardening policies. Engine-dependent controls are represented as
/// explicit policies and adapters so the application never falsely claims
/// a WebView capability that it cannot enforce.
library;

enum PrivacyCapability {
  privateProfileIsolation,
  trackerBlocking,
  adBlocking,
  thirdPartyCookiePartitioning,
  fingerprintResistance,
  canvasProtection,
  webglFingerprintMitigation,
  webrtcLeakProtection,
  dohDotPolicy,
  certificateSecurity,
}

enum SearchCapability {
  autocomplete,
  suggestions,
  typoCorrection,
  ranking,
  trending,
  regionLanguage,
  shoppingProvider,
}

enum AiCapability {
  streaming,
  providerTokenAccounting,
  conversationFolders,
  workspace,
  multiConversation,
}

enum NotebookCapability {
  backlinks,
  clipping,
  highlights,
  exportMarkdownPdf,
  autosave,
  versionHistory,
  aiActions,
}

enum LibraryCapability {
  readingList,
  archivedPages,
  importExport,
  sync,
  duplicateDetection,
}

class BrowserSecurityPolicy {
  const BrowserSecurityPolicy({
    this.privateProfileIsolation = true,
    this.trackerBlocking = true,
    this.adBlocking = true,
    this.thirdPartyCookiePartitioning = true,
    this.fingerprintResistance = true,
    this.canvasProtection = true,
    this.webglFingerprintMitigation = true,
    this.webrtcLeakProtection = true,
    this.dohDotPolicy = true,
    this.certificateSecurity = true,
  });

  final bool privateProfileIsolation;
  final bool trackerBlocking;
  final bool adBlocking;
  final bool thirdPartyCookiePartitioning;
  final bool fingerprintResistance;
  final bool canvasProtection;
  final bool webglFingerprintMitigation;
  final bool webrtcLeakProtection;
  final bool dohDotPolicy;
  final bool certificateSecurity;
}

class SearchPolicy {
  const SearchPolicy({
    this.autocomplete = true,
    this.suggestions = true,
    this.typoCorrection = true,
    this.ranking = true,
    this.trending = true,
    this.regionLanguage = true,
    this.shoppingProvider = true,
  });

  final bool autocomplete;
  final bool suggestions;
  final bool typoCorrection;
  final bool ranking;
  final bool trending;
  final bool regionLanguage;
  final bool shoppingProvider;
}

class AiWorkspacePolicy {
  const AiWorkspacePolicy({
    this.streaming = true,
    this.providerTokenAccounting = true,
    this.conversationFolders = true,
    this.workspace = true,
    this.multiConversation = true,
  });

  final bool streaming;
  final bool providerTokenAccounting;
  final bool conversationFolders;
  final bool workspace;
  final bool multiConversation;
}

class NotebookPolicy {
  const NotebookPolicy({
    this.backlinks = true,
    this.clipping = true,
    this.highlights = true,
    this.exportMarkdownPdf = true,
    this.autosave = true,
    this.versionHistory = true,
    this.aiActions = true,
  });

  final bool backlinks;
  final bool clipping;
  final bool highlights;
  final bool exportMarkdownPdf;
  final bool autosave;
  final bool versionHistory;
  final bool aiActions;
}

class LibraryPolicy {
  const LibraryPolicy({
    this.readingList = true,
    this.archivedPages = true,
    this.importExport = true,
    this.sync = true,
    this.duplicateDetection = true,
  });

  final bool readingList;
  final bool archivedPages;
  final bool importExport;
  final bool sync;
  final bool duplicateDetection;
}

class AdvancedBrowserConfiguration {
  const AdvancedBrowserConfiguration({
    this.security = const BrowserSecurityPolicy(),
    this.search = const SearchPolicy(),
    this.ai = const AiWorkspacePolicy(),
    this.notebook = const NotebookPolicy(),
    this.library = const LibraryPolicy(),
  });

  final BrowserSecurityPolicy security;
  final SearchPolicy search;
  final AiWorkspacePolicy ai;
  final NotebookPolicy notebook;
  final LibraryPolicy library;
}

/// Declares what this Flutter layer can enforce locally and what requires
/// a platform/browser-engine adapter. Keeping this distinction explicit is
/// essential for an honest production security posture.
class EngineAdapterContract {
  const EngineAdapterContract();

  bool get supportsIndependentWebViewProfile => false;
  bool get supportsNetworkDnsPolicy => false;
  bool get supportsLowLevelWebRtcControl => false;
  bool get supportsCertificateInterception => false;
  bool get supportsCanvasWebglMitigation => false;
  bool get supportsNativeCookiePartitioning => false;
}
