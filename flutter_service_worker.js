'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {".git/COMMIT_EDITMSG": "4afe0604b3a633e0ca6fcd7a74788162",
".git/config": "3800dedcb0d3bf98419a138d7fe65e62",
".git/description": "a0a7c3fff21f2aea3cfa1d0316dd816c",
".git/HEAD": "cf7dd3ce51958c5f13fece957cc417fb",
".git/hooks/applypatch-msg.sample": "ce562e08d8098926a3862fc6e7905199",
".git/hooks/commit-msg.sample": "579a3c1e12a1e74a98169175fb913012",
".git/hooks/fsmonitor-watchman.sample": "a0b2633a2c8e97501610bd3f73da66fc",
".git/hooks/post-update.sample": "2b7ea5cee3c49ff53d41e00785eb974c",
".git/hooks/pre-applypatch.sample": "054f9ffb8bfe04a599751cc757226dda",
".git/hooks/pre-commit.sample": "5029bfab85b1c39281aa9697379ea444",
".git/hooks/pre-merge-commit.sample": "39cb268e2a85d436b9eb6f47614c3cbc",
".git/hooks/pre-push.sample": "2c642152299a94e05ea26eae11993b13",
".git/hooks/pre-rebase.sample": "56e45f2bcbc8226d2b4200f7c46371bf",
".git/hooks/pre-receive.sample": "2ad18ec82c20af7b5926ed9cea6aeedd",
".git/hooks/prepare-commit-msg.sample": "2b5c047bdb474555e1787db32b2d2fc5",
".git/hooks/push-to-checkout.sample": "c7ab00c7784efeadad3ae9b228d4b4db",
".git/hooks/sendemail-validate.sample": "4d67df3a8d5c98cb8565c07e42be0b04",
".git/hooks/update.sample": "647ae13c682f7827c22f5fc08a03674e",
".git/index": "887d7a3c083bc807a9370b3a3b9b1edd",
".git/info/exclude": "036208b4a1ab4a235d75c181e685e5a3",
".git/logs/HEAD": "d84c89a6a03a17dc0d0416a6c4e09373",
".git/logs/refs/heads/main": "88dd1c84ffb13fe082fff2714138b803",
".git/logs/refs/remotes/origin/main": "c300f6da63bad637bdcddeed97e7d4ae",
".git/objects/04/598b97d54f26fc3352367e8e58b4d1d2c7ee70": "e9c8e7c286b7b7def8fbe89531ad0544",
".git/objects/04/65ecaa3e68341cef4e7136166ed13491c58e78": "41263cfe0eed3820cfaea517c3eaae1e",
".git/objects/05/e0157fcb9ddb76bb8f681c2ee100fff92c2cd1": "0717bd2e8288ed5f181c0a704d54b511",
".git/objects/06/5a156ad876ae75d08bca0aabc8c1e01f285abb": "1338ac20d12542d14345378e2fe2be26",
".git/objects/0e/8b05e523ed6a05cd1192425f69607082627fc9": "713977deed0567d0d9a5dd2fa21dcf81",
".git/objects/14/a00d82788c3674bc014775ac0919d608a046cc": "d574b09fe21c268a76756acf77853f84",
".git/objects/15/7bbeffe02fda1be07f580ef0e4f6d2b53fefd7": "e3fd46bf87febc8430e59a33e5e879ae",
".git/objects/20/7f4bfce27ae1dd77283f874c28aece65285d02": "82c560f867f4f3ef97dea6ad5492b5bf",
".git/objects/29/32b0c234be1e7862fa84ac46cb2390ec4975fb": "e086ea897728b3944eb96812ad9205fb",
".git/objects/2c/f462da537f8e10d180f2e54ca5c75e298cfbf6": "25693382a8779449d94c8c140a8e5a63",
".git/objects/2d/0471ef9f12c9641643e7de6ebf25c440812b41": "d92fd35a211d5e9c566342a07818e99e",
".git/objects/31/b62f01d7d552036080ab3c17d92ff68798eb7c": "23334591a3bf4f484b99e223d6e3e4b4",
".git/objects/34/27be90c6eeb9df43357df25fd399639f75a51e": "6e5d1e65bade61e78dd9c3e479671eb1",
".git/objects/35/6fbcb1d8500cd8562640e513128e238c66fe82": "64b6510952485fc84bd00c3c083f5271",
".git/objects/3a/bf18c41c58c933308c244a875bf383856e103e": "30790d31a35e3622fd7b3849c9bf1894",
".git/objects/3b/b0860a0981211a1ab11fced3e6dad7e9bc1834": "3f00fdcdb1bb283f5ce8fd548f00af7b",
".git/objects/43/06fe03d255dccb99facb580d2d53bcdc651d94": "9a058f8f1e3471afbd97d81c01ffc203",
".git/objects/54/8d1f5db71a877e28abd67b880d048d77bf90f2": "16df6c972ef5f227ba1eb3832094dedc",
".git/objects/56/ec545a84f012d9740596b2eb75452bb4eea687": "704881f13fac1368cac6ba528ff2f280",
".git/objects/57/e39298079bfb668ae8b918ba17aae365c95875": "6021a82d51b057feab37fc52e2955ae5",
".git/objects/5a/c43cdae92e110447d4d7d19f14045c01933988": "9f2e5a0ad4236ce3223aa8f991f7fd90",
".git/objects/60/53ee99086d39d88600dd168f911537543902eb": "bb3c39bdd16bd157a31ba5f031516583",
".git/objects/60/945552bd06b85d105d518f010895ae6484df84": "da8e38cae534d3b7f2d9fe23f3f14c8e",
".git/objects/79/7959822598d0170749a1e9c20998c90e517f92": "8cf1ab3e3610395190406ba5dfc4a74d",
".git/objects/81/0c42f9e9eac60741ab7dc9d380247fae581750": "a792bdb52762441b65adeba355c89ece",
".git/objects/86/a5be6aaf3b1fcdef93869da6e423d694be2af4": "8bba50b9c8a8a958e98b82cfc4706f9f",
".git/objects/88/cfd48dff1169879ba46840804b412fe02fefd6": "e42aaae6a4cbfbc9f6326f1fa9e3380c",
".git/objects/8a/aa46ac1ae21512746f852a42ba87e4165dfdd1": "1d8820d345e38b30de033aa4b5a23e7b",
".git/objects/93/b71e11deb0e6295a067ac46831ea6ce2676c0b": "ca74f8d4f5a2cf3a0f774d19fbfaf89c",
".git/objects/97/004061ccd5cf7a79346eb72287959a14e9ed15": "f8e5a52d85d6f04a4aab1677f64a0eae",
".git/objects/9b/150820ff777938350d4749b54677ff92b09436": "afbbe49a11e3f3be527e6848decb986f",
".git/objects/a3/f6a24aff9792a4b3b34381ac7f98d53dd7392a": "0b96d2e163f75dc001647a8b2399062a",
".git/objects/ab/23a5aa4605e778018ba39284cb2757cb6fa0b7": "bc5bd593007de22ba0ab6b85cc198dec",
".git/objects/b6/8a2f6a6362ba2a387a8d5abb7fd364b7d299a1": "10b1750f4f0bf50ee256fcc2bbc34410",
".git/objects/b7/49bfef07473333cf1dd31e9eed89862a5d52aa": "36b4020dca303986cad10924774fb5dc",
".git/objects/b9/2a0d854da9a8f73216c4a0ef07a0f0a44e4373": "f62d1eb7f51165e2a6d2ef1921f976f3",
".git/objects/bc/d2900102e092a57c23752143e1782fe388211e": "f7077ae78c9b6e3a5ff2e83b03ebaea4",
".git/objects/c7/7663172ca915a99a594ca17d06f527db05657d": "6335b074b18eb4ebe51f3a2c609a6ecc",
".git/objects/ce/ab699c7bdd3c3ff2c96642f7a2a18832883ede": "dbe2763a211ba43c52a498e4c5af1c40",
".git/objects/d0/f3811e7d5fd633862088364edb9363d253305a": "2c47c7549dbf6cf6f4e385e83b5f1223",
".git/objects/d4/3532a2348cc9c26053ddb5802f0e5d4b8abc05": "3dad9b209346b1723bb2cc68e7e42a44",
".git/objects/d6/9c56691fbdb0b7efa65097c7cc1edac12a6d3e": "868ce37a3a78b0606713733248a2f579",
".git/objects/d7/076b56fc9cd031b73ebf1be668edbc58d16f4a": "29894a0040d6166e043eaa9b70c4e30f",
".git/objects/eb/9b4d76e525556d5d89141648c724331630325d": "37c0954235cbe27c4d93e74fe9a578ef",
".git/objects/f2/04823a42f2d890f945f70d88b8e2d921c6ae26": "6b47f314ffc35cf6a1ced3208ecc857d",
".git/objects/fa/9495f74f62967adc5aec8571bcf76a71b4eeb0": "cc1deed694bae16b5e10888e4cb74f5f",
".git/objects/fc/229b7429af4db2bd6deb640abcf960192bedcb": "9c78f31cab79c167ca83c889085acc85",
".git/objects/fe/2ef923ffd9c2a6e751bc373030809b7cac0afc": "fb92ffc8ceb72e230c2ea7660ee9efd7",
".git/refs/heads/main": "da63375b375a212a9dfcb1e10799112d",
".git/refs/remotes/origin/main": "da63375b375a212a9dfcb1e10799112d",
"assets/AssetManifest.bin": "682b0cd81afa07c5bd9b0f3b4a3c8bda",
"assets/AssetManifest.bin.json": "75de95393479205e106a870b11542380",
"assets/AssetManifest.json": "4299edbed6b51cf79fd3d2f2603bdf21",
"assets/assets/ejemplo.json": "67bf393c66d54dfb8062e2ed3448147e",
"assets/assets/loading.gif": "372cd3ce4d67057abf98c70121213171",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/fonts/MaterialIcons-Regular.otf": "3e590710890cd17c02060464c1e52345",
"assets/NOTICES": "6305cae0b7e3bd741cc0bea17207ea8b",
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
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"flutter.js": "1e28bc80be052b70b1e92d55bea86b2a",
"flutter_bootstrap.js": "3d2f448a2f77a6c8adf24976f1a2c3a6",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"index.html": "dc4d7529fc5f1b9eebb4b6bc384d92ec",
"/": "dc4d7529fc5f1b9eebb4b6bc384d92ec",
"main.dart.js": "7334cc40bee0de66b8b7a756cfbefa0b",
"manifest.json": "e7c6e3f8a5fd4c29f897ad651d4e8350",
"version.json": "f0fc8a295cf13fc545b2a0778b548a7a"};
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
