'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"assets/AssetManifest.bin": "3d14e58fb27c477ab795c7814164ea57",
"assets/AssetManifest.bin.json": "f447d2025247384887c43c08bc171d78",
"assets/AssetManifest.json": "1f47823320d3bc2e056fae41a70b0aa1",
"assets/assets/buscando.json": "7aa97258ea1e33b204d22d8b0e8aeefc",
"assets/assets/guide/step1.jpg": "c891b00d7c28579685c14327c35f12b9",
"assets/assets/guide/step2.jpg": "5823e26fc6ecdda25f7e7d0198395f04",
"assets/assets/guide/step2b.jpg": "2d00821bd19eef19c856e47fd0482e5d",
"assets/assets/guide/step2c.jpg": "614ccca56659ee52e63dde6a915caf48",
"assets/assets/guide/step2d.jpg": "4bbf8508f052546df61eb944cab18814",
"assets/assets/guide/step3.jpg": "466bb06bfc218fc9d8921e4e2caa537d",
"assets/assets/guide/step4.jpg": "796eb6a9436694487b3db6cd6c6b857a",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/fonts/MaterialIcons-Regular.otf": "bc37d9c451fcce621703d22982f5ce3c",
"assets/NOTICES": "1f2d0613d0addb947516122a8e3fcbf5",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/packages/fluttertoast/assets/toastify.css": "a85675050054f179444bc5ad70ffc635",
"assets/packages/fluttertoast/assets/toastify.js": "56e2c9cedd97f10e7e5f1cebd85d53e3",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"canvaskit/canvaskit.js": "8cf6e87eff144e2453a9640bfa1a4ad0",
"canvaskit/canvaskit.js.symbols": "9cd6c6f6517e7d232456285d2e0f4b9a",
"canvaskit/canvaskit.wasm": "4ea42381471802a2faf8401a6ad48526",
"canvaskit/chromium/canvaskit.js": "9dc7a140b1f0755e6321e9c61b9bd4d9",
"canvaskit/chromium/canvaskit.js.symbols": "e878fd5eeae47b666d050659717fe4c4",
"canvaskit/chromium/canvaskit.wasm": "2014f27e70ce7b7b575f8498fd6c45d1",
"canvaskit/skwasm.js": "9c817487f9f24229450747c66b9374a6",
"canvaskit/skwasm.js.symbols": "86e2c491901be286643b22ecab174245",
"canvaskit/skwasm.wasm": "ea23b36a4e9108cc6c4dfd12fc3fe28c",
"canvaskit/skwasm_st.js": "7df9d8484fef4ca8fff6eb4f419a89f8",
"canvaskit/skwasm_st.js.symbols": "25c9845221ee0dd39b173a8caf499c4b",
"canvaskit/skwasm_st.wasm": "a45e6d297c0d4c452d7a7ebb5cc56624",
"favicon.png": "df917c9edfff02a4ad1f1f9828e89bd2",
"favicon2.svg": "0e12a4086d18c51372c685a5ad3649d3",
"flutter.js": "1e28bc80be052b70b1e92d55bea86b2a",
"flutter_bootstrap.js": "bb3f001edb0c8c0b0cce8ebbae0dfcf0",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"index.html": "dc4d7529fc5f1b9eebb4b6bc384d92ec",
"/": "dc4d7529fc5f1b9eebb4b6bc384d92ec",
"main.dart.js": "ed4528463f5c2e409d6b83e6697e0ae3",
"manifest.json": "e7c6e3f8a5fd4c29f897ad651d4e8350",
"version.json": "69111717f93e69f28d6046179410e7bc"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
