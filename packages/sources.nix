pkgs: {
  v3 = pkgs.fetchurl {
    url = "https://web.archive.org/web/20260206191533/https://downloads.affinity.studio/Affinity%20x64.msix";
    hash = "sha256-Ys2YarvIjfWlEIGZyft3M0o+4tLAcfhn89t7ucRq+vY=";
  };

  photo = pkgs.fetchurl {
    url = "https://web.archive.org/web/20251216034410/https://d1gl0nrskhax8d.cloudfront.net/windows/photo2/2.6.5/affinity-photo-2.6.5.msix?Expires=1765859862&Signature=q~AGhFL4eA2M5AaZLbLEPnqHP3r3Kltmgts6VhIp8bRfGfpBEO0sYM5JUYbP-A-rSPmrqiqymJpCSjOx9y9PUsN4Oq2VP8fybHqcJhcAPSnjoTWvBZnSJUKOJE2TptAscxFFChaAFwT73eWfsEv0pEUpURhoSslMCoFfAA0SF9dNhLnB8i1lANr~uNsDT3SXJU3MivIseGmfBWilE8S8LdVIFqZFaGs~9nxBxtwiy-iNxV8e-orL7~TktLp7UyfZ6dQvvdrMkuC4nx9qabMA7-RLfU65x1CWelEUTA~fUkVWQsHpeRFSaAE~QRkNJAcinx3m8jKZgXViToTYNjqdoQ__&Key-Pair-Id=APKAIMMPYSI7GSVTEAAQ";
    hash = "sha256-roKSVbNEl0KUjKuAyt+F6MGGRMm6+E/vKVtcVAR1MSQ=";
  };

  designer = pkgs.fetchurl {
    url = "https://web.archive.org/web/20251219010948/https://d1gl0nrskhax8d.cloudfront.net/windows/designer2/2.6.5/affinity-designer-2.6.5.msix?Expires=1766110073&Signature=ZK9w20msfg3Z8D3PaQOUIExaXDK12lbfN7QOBUXSM-nxVy8ReDf5~G1LMUifpu6RGi6VVii9X8GF~QslhtlJtHrDMMQB4kBdEuTqvsUwpnHlZUc0z~FHj~4CfSWIBOZmsV2KIBLHQwADSvnDuWyz3wkAs48grmZMRcOsK~8v4ywtzQ9vx3alnP2xeeCSCaTKlf3nVqd785TDuAYKJRo5bM-NQT1UjSv68Yxwn7nCpJqWepo7X-0lR4TQ6bnSEm-i19cqvg4ifDcsVftPXuHqEWpjFClnh2cq8-Sf5obV7cxEsq6OK3qp5cpYLdhuD5Tllu-cv67JdEzFO0IJC5zVQg__&Key-Pair-Id=APKAIMMPYSI7GSVTEAAQ";
    hash = "sha256-uGnnZVLviW88n3Z8uaSWlQYyuTIXdMvf1jyrWWvQ1s0=";
  };

  publisher = pkgs.fetchurl {
    url = "https://web.archive.org/web/20260411055712/https://d1gl0nrskhax8d.cloudfront.net/windows/publisher2/2.6.5/affinity-publisher-2.6.5.msix?Expires=1775890429&Signature=E9~UY5P3Q9vkDaH3GpVhmV1pDWaC86tdKG5CIfhBJAzGcyhej2gWswgb0FEVBuHTc3-WU~MqR5j3cKyXOTprUXlBXP8ltwm9jGw2ZsBxt8WLNlKhzBI5LOLqFCxbYWVTZHWWzfu7ZJrrms2JSc6hXdlUD9P7etH5p7KI7baQYWUvHmZmUqsP8ljN5KZAGyPIVi0yHkycqgqFDoHG2t53Ss0CWK04uNhx2~IZ1D1pC5rOcJp6acrYt3ZRsyN9JjBxMenikJEPlNjQClXjw1O756F5CQ-Cy3xNL1axxHyJ0wD9MguQWpd7cDw1u0vfZkAFY92sPtlrpvYyc9YTmfnEjQ__&Key-Pair-Id=APKAIMMPYSI7GSVTEAAQ";
    hash = "sha256-+rkl84BzOmW+UXgFxNfAhqmLR11CV0uolIVG9wktE8w=";
  };
}
