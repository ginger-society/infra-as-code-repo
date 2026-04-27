## 0.30.0-nightly.0 - 2026-04-27
chore:
 - [b02de416cd](https://github.com/ginger-society/infra-as-code-repob02de416cd4e2ef770f2acc27ebcdc1731025076) (Ginger Society Admin) chore: version bump to 0.29.0-nightly.0
	
 - [01089c8be6](https://github.com/ginger-society/infra-as-code-repo01089c8be664378384932c24243637e1a34ba9b4) (Ginger Society Admin) chore: version bump to 0.29.0-nightly.0
	
 - [7d9295af0b](https://github.com/ginger-society/infra-as-code-repo7d9295af0bd234cd381e73818cfd8ee5ea494e7e) (Ginger Society Admin) chore: version bump to 0.29.0-nightly.0
	
## 0.29.0-nightly.0 - 2026-04-27
feat:
 - [515c369307](https://github.com/ginger-society/infra-as-code-repo515c3693079c9312c57a1da8c205097f104943f1) (Ginger Society Admin) feat: added kube service and fixing pipeline
	
 - [9f233b77b6](https://github.com/ginger-society/infra-as-code-repo9f233b77b64af68e907a2c9a1cacfd853481b537) (Ginger Society Admin) feat: added envrc
	
 - [2fdbc54fe1](https://github.com/ginger-society/infra-as-code-repo2fdbc54fe1fda97899b9edf4d1452a42438b4fd1) (Ginger Society Admin) feat: making db compose part of core service
	
 - [0d1bcd027c](https://github.com/ginger-society/infra-as-code-repo0d1bcd027c197ae5e9291740b776b7daccc31d20) (Ginger Society Admin) feat: published rabbitmq chart to the artifact
	
 - [3cda44babe](https://github.com/ginger-society/infra-as-code-repo3cda44babed24bd7a680f8b7173a1c59cdf15f8e) (Ginger Society Admin) feat: updated iam admin deployment to use secrets
	
 - [4d8b4763fd](https://github.com/ginger-society/infra-as-code-repo4d8b4763fdc4b6acabf148e570614d6feffbe339) (Ginger Society Admin) feat: updated notification service deployment to use secrets
	
 - [369d91e8c8](https://github.com/ginger-society/infra-as-code-repo369d91e8c8340081b4cec8a5a0fb39116bec2df2) (Ginger Society Admin) feat: added amqp url to rabitmq helm chart
	
 - [3d5d33e8ae](https://github.com/ginger-society/infra-as-code-repo3d5d33e8ae243763c9af6f073a8f387f0fb6e957) (Ginger Society Admin) feat: updated metadata service to use env variables from secrets
	
 - [12cb60331e](https://github.com/ginger-society/infra-as-code-repo12cb60331e189b6116298dfa8f210c9ee7c7f83b) (Ginger Society Admin) feat: updated metadata db deployment to use secrets
	
 - [64a5685e1e](https://github.com/ginger-society/infra-as-code-repo64a5685e1e36b5ab9060154d71b04921e65164e6) (Ginger Society Admin) feat: sourcing the entire db url from secret
	
 - [2434404473](https://github.com/ginger-society/infra-as-code-repo2434404473bc84397f9e1e3eef5b8e7c78790919) (Ginger Society Admin) feat: updated iam db runtime to use secrets
	
 - [b424cfaa8f](https://github.com/ginger-society/infra-as-code-repob424cfaa8fbbd1bd52c905adefe0339f3442973d) (Ginger Society Admin) feat: updated iam service deployment to use secrets and added readme to create them
	
 - [fcf23d1667](https://github.com/ginger-society/infra-as-code-repofcf23d16672a7bc29f1781430a1521eec61df421) (Ginger Society Admin) feat: added rds and rabbitmq helm based installation details and charts
	
 - [cbd5129dd0](https://github.com/ginger-society/infra-as-code-repocbd5129dd0434cb8641b91a8a679a844ca4a6877) (Ginger Society Admin) feat: added rdb config in shared components to be used with helm
	
 - [65ee105a39](https://github.com/ginger-society/infra-as-code-repo65ee105a393e5180d19f723d2ed1fff619a18868) (GingerSociety Admin) feat: added tekton pipeline file and updated different deployments to use registry credentials
	
 - [f1fbc90306](https://github.com/ginger-society/infra-as-code-repof1fbc90306ecfab5dfb6aec70df3da00f2ab935b) (GingerSociety Admin) feat: added longhorn and images endpoint and also added wait for pg service to be available before starting rust based services
	
 - [47296a8715](https://github.com/ginger-society/infra-as-code-repo47296a871594164145b2b74a407a4579491fd5e6) (GingerSociety Admin) feat: added coder env and created git and buildah images
	
 - [4bb15c0520](https://github.com/ginger-society/infra-as-code-repo4bb15c052025e12b31c6d92c82e96e3e2636b977) (GingerSociety Admin) feat: renamed docker to containers
	
 - [4e4d87130b](https://github.com/ginger-society/infra-as-code-repo4e4d87130bf2b4d4d5801619682f17332cd83d67) (GingerSociety Admin) feat: updated hello world task to apply the migrations and added read only deployment for registry
	
 - [02cbd09296](https://github.com/ginger-society/infra-as-code-repo02cbd092960328e2e6be10ebdf09b1a3ee0c85cd) (GingerSociety Admin) feat: added kubectl auth in the step
	
 - [ab300fe38e](https://github.com/ginger-society/infra-as-code-repoab300fe38e9ef441e9d9f8c27452c63c6cfa700b) (GingerSociety Admin) feat: added iam admin service in stage
	
 - [e63dc6bf12](https://github.com/ginger-society/infra-as-code-repoe63dc6bf120609cda800cb521de23cea52672d94) (GingerSociety Admin) feat: adding tekton related examples
	
 - [eb6f1faa99](https://github.com/ginger-society/infra-as-code-repoeb6f1faa99ec9142442a7c952b1e5dcfcfaef75c) (GingerSociety Admin) feat: added rabbitmq, test envs for ginger db , added notification service
	
 - [a6b1dac69b](https://github.com/ginger-society/infra-as-code-repoa6b1dac69b22171a693cc6de814b0acc03ee6156) (GingerSociety Admin) feat: added redis , dev portal , file browser , pip , docker registry , node registry
	
 - [7ee7cc5218](https://github.com/ginger-society/infra-as-code-repo7ee7cc5218c2c298fd13b45c939dfce7876f5af7) (GingerSociety Admin) feat: added verdaccio and gitweb
	
 - [8fdf18e04b](https://github.com/ginger-society/infra-as-code-repo8fdf18e04bb189c9e0713e1c1be81300e7046fc5) (GingerSociety Admin) feat: added metadata for testing , updated kg dashboard permission
	
 - [998f4cf7b8](https://github.com/ginger-society/infra-as-code-repo998f4cf7b8cc7dd8006b8dd3450f87cf21cc3f45) (GingerSociety Admin) feat: added git clone example in tekton
	
 - [5808134b77](https://github.com/ginger-society/infra-as-code-repo5808134b770ea2f18b90396688498f4c3d13934e) (GingerSociety Admin) feat: added gitolite
	
 - [60b8822afc](https://github.com/ginger-society/infra-as-code-repo60b8822afc0926c80e78bfa58b08e1fc09a3a43a) (GingerSociety Admin) feat: added k8 dashboard with read only role
	
 - [5f9cfe0500](https://github.com/ginger-society/infra-as-code-repo5f9cfe0500cb6dbb95705c50c3d1454e84c2ea3e) (GingerSociety Admin) feat: added sample db migration tekton script and an example on how to build docker image
	
 - [3dd9a1a773](https://github.com/ginger-society/infra-as-code-repo3dd9a1a773475300915c708a76e03927b5f3d635) (GingerSociety Admin) feat: added tekton and pgadmin
	
 - [4002027792](https://github.com/ginger-society/infra-as-code-repo4002027792165a838f5d7733ad2d50cfdecc4864) (GingerSociety Admin) feat: added iam frontend service
	
 - [bffe4110a1](https://github.com/ginger-society/infra-as-code-repobffe4110a196704118bb0e9613ca918ac4df86db) (GingerSociety Admin) feat: added apache conf for prod env
	
 - [0186cd1dec](https://github.com/ginger-society/infra-as-code-repo0186cd1decfb72ac1285e4b5924755ca4ce66960) (Ginger Society) feat: changing to prod
 - [96371008cc](https://github.com/ginger-society/infra-as-code-repo96371008ccaf79afdc1a38c88056939b463065fe) (Ginger Society Admin) feat: changing rust rocket runner to use bullseye image of debian
	
 - [54b16ba4ec](https://github.com/ginger-society/infra-as-code-repo54b16ba4ec768518c6b76e945c5d6ddac112810a) (Ginger Society Admin) feat: updated docker image and added openssl in pipeline
	
 - [965bb011ef](https://github.com/ginger-society/infra-as-code-repo965bb011ef64a5347c8507d2368a9ef6ee9ba7f1) (Ginger Society Admin) feat: updated pipeline dispatch trigger
	
 - [0abd74b0f7](https://github.com/ginger-society/infra-as-code-repo0abd74b0f7700380e509b1a59cebcf0959962f4f) (Ginger Society Admin) feat: added prometheus , pgsql , rabbitmq and redis exporters
	
 - [d9e97b3b42](https://github.com/ginger-society/infra-as-code-repod9e97b3b42df6a2ecde14123ee514710c5d4b74f) (Ginger Society Admin) feat: added prod env and refactored to separate the environments under their own folder
	
 - [f0c01ea392](https://github.com/ginger-society/infra-as-code-repof0c01ea3922481dabded7e52ea2a6695e22f2d4c) (Ginger Society Admin) feat: added updated env variables and updated readme
	
 - [a2021bfe81](https://github.com/ginger-society/infra-as-code-repoa2021bfe8127c6e80febf7d9a5f661d4814a9410) (Ginger Society Admin) feat: updated metadata
	
fix:
 - [2ecfcaf0e2](https://github.com/ginger-society/infra-as-code-repo2ecfcaf0e2d26a3a0d7f733dbeb6745653426003) (Ginger Society Admin) fix: ip for db compose test env
	
 - [e0e37f7795](https://github.com/ginger-society/infra-as-code-repoe0e37f7795a3277ea2bab817b3b7e91cbe205825) (Ginger Society Admin) fix: amqp url formating in helm chart
	
 - [fde8ef7686](https://github.com/ginger-society/infra-as-code-repofde8ef7686b757560420fd7eec995eb7e20fc96f) (Ginger Society Admin) fix: pg bind port
	
 - [064c66d211](https://github.com/ginger-society/infra-as-code-repo064c66d2111a86325cc17fff6b823b14dc5288a5) (Ginger Society Admin) fix: pgadmin probe too high
	
 - [cddf502695](https://github.com/ginger-society/infra-as-code-repocddf5026950be58e75527aad184b355267bed74d) (Ginger Society Admin) fix: removed hardcoded dependency on internal IP
	
 - [0c0da09b6c](https://github.com/ginger-society/infra-as-code-repo0c0da09b6cff4c71c4019f2953708d18c9004620) (Ginger Society Admin) fix: changing runner image to use buster tag of debian
	
chore:
 - [b2f85087fd](https://github.com/ginger-society/infra-as-code-repob2f85087fd012eaa13254b2f85888a3071ab243c) (Ginger Society Admin) chore: version bump to 0.29.0-nightly.0
	
 - [2d65567f38](https://github.com/ginger-society/infra-as-code-repo2d65567f38833eebd3635cb2896f36cb1fb0571f) (Ginger Society Admin) chore: cleanup and notes
	
 - [bd3ddc5711](https://github.com/ginger-society/infra-as-code-repobd3ddc5711e918dd870dda1c0713a29846d2c26a) (Ginger Society Admin) chore: testing helm chart publishing
	
 - [a123255ca6](https://github.com/ginger-society/infra-as-code-repoa123255ca6841e1c0480a47613db88a59defc89a) (Ginger Society Admin) chore: testing helm publishing
	
 - [550b12d9b8](https://github.com/ginger-society/infra-as-code-repo550b12d9b842a364a95c176ff1428d85caaacbf6) (Ginger Society Admin) chore: testing helm repo hosting
	
 - [1816eb9895](https://github.com/ginger-society/infra-as-code-repo1816eb9895a76cc120cb8f4970d11c665db38e20) (Ginger Society Admin) chore: minor changes
	
 - [24c44d9d23](https://github.com/ginger-society/infra-as-code-repo24c44d9d2348802d555e9ecc20c4b896172dd83d) (Ginger Society Admin) chore: minor fixes and readme updates
	
 - [70ffd49ad4](https://github.com/ginger-society/infra-as-code-repo70ffd49ad4236f91160abe4f5190503fb4f6848f) (Ginger Society Admin) chore: minor readme changes
	
 - [f94a573d44](https://github.com/ginger-society/infra-as-code-repof94a573d44c1204dbf13e7a2cbd826c141ff5527) (Ginger Society Admin) chore: minor fixes
	
 - [83f7268323](https://github.com/ginger-society/infra-as-code-repo83f72683233c090a75396bed680e41c2507b1525) (Ginger Society Admin) chore: minor
	
 - [5bb5978952](https://github.com/ginger-society/infra-as-code-repo5bb597895235b9318858ecaeec3c32e5baac05c0) (Ginger Society Admin) chore: minor changes
	
 - [7be9c7ad5c](https://github.com/ginger-society/infra-as-code-repo7be9c7ad5cef29f4a1c8cfe1822eadc7a031316b) (Ginger Society Admin) chore: minor
	
 - [22c00cd5ba](https://github.com/ginger-society/infra-as-code-repo22c00cd5bac3d892e723b12810f2f782bdf430c7) (Ginger Society Admin) chore: minor
	
 - [efc871e8e9](https://github.com/ginger-society/infra-as-code-repoefc871e8e96c2eccef1032b9eff8a4fa21d8d2d4) (Ginger Society Admin) chore: updated pgadmin service name in ingress
	
 - [151095bf73](https://github.com/ginger-society/infra-as-code-repo151095bf7393aedc095fe9ce9368313db3f096e1) (Ginger Society Admin) chore: refactored apache2 config into mission critical services and infra services
	
 - [c65702f25a](https://github.com/ginger-society/infra-as-code-repoc65702f25a419804f56e095f56f86b87bcd850a0) (GingerSociety Admin) chore: version bump to 0.28.0-nightly.0
	
 - [deac872246](https://github.com/ginger-society/infra-as-code-repodeac872246211a41f71d584846ec6fa492b48ff5) (GingerSociety Admin) chore: minor
	
 - [c71d35345f](https://github.com/ginger-society/infra-as-code-repoc71d35345f8ca24badae7c4f6d0f9701389b0058) (Ginger Society) chore: changing CI image to ubuntu 20
## 0.27.0-nightly.0 - 2024-10-07
chore:
 - [a061dc7ed1](https://github.com/ginger-society/infra-as-code-repoa061dc7ed18ce8db9c5f1d18075d23f6a3b2f0e8) (Ginger Society Admin) chore: version bump to 0.27.0-nightly.0
	
feat:
 - [5689a0b2a1](https://github.com/ginger-society/infra-as-code-repo5689a0b2a1fc51167a3cd3d0733b3f3dfbb53ce8) (Ginger Society Admin) feat: added google console link
	
 - [e08efbd51f](https://github.com/ginger-society/infra-as-code-repoe08efbd51f90dd141c2697ce30c9e73fa160bdb4) (Ginger Society Admin) feat: updated pipeline since the api token age has been revised to 20 minutes
	
 - [a577f6bd53](https://github.com/ginger-society/infra-as-code-repoa577f6bd536702671eeadfb3ae679f39c1cd896f) (Ginger Society Admin) feat: fixing ginger auth expiration issue in pipeline
	
 - [3b7ca13139](https://github.com/ginger-society/infra-as-code-repo3b7ca131395891b77190a52348e29b6aada6b1a0) (Ginger Society Admin) feat: updated pipeline to trigger system wide check
	
## 0.24.0-nightly.0 - 2024-10-03
chore:
 - [e215966126](https://github.com/ginger-society/infra-as-code-repoe2159661260ff524b5964c0e67ef095f187b497f) (Ginger Society Admin) chore: version bump to 0.24.0-nightly.0
	
 - [246b4b2ab7](https://github.com/ginger-society/infra-as-code-repo246b4b2ab7fc76e66cdbccb409b982640d150d9b) (Ginger Society) chore: Rename readme.md to README.md
## 0.23.0-nightly.0 - 2024-10-03
chore:
 - [637349cd45](https://github.com/ginger-society/infra-as-code-repo637349cd459bd895f69594cd7b5c7fba39fc73f0) (Ginger Society Admin) chore: version bump to 0.23.0-nightly.0
	
## 0.22.0-nightly.0 - 2024-10-03
chore:
 - [95634cbef1](https://github.com/ginger-society/infra-as-code-repo95634cbef194c6a83aa1f88d03ddf2575c70326f) (Ginger Society Admin) chore: version bump to 0.22.0-nightly.0
	
## 0.21.0-nightly.0 - 2024-10-03
feat:
 - [866c40cc36](https://github.com/ginger-society/infra-as-code-repo866c40cc367fdbce418825b0c626c394a43fd54f) (Ginger Society Admin) feat: updated docker images to use only pipeline essential dockerfile
	
 - [ffe2b06dbe](https://github.com/ginger-society/infra-as-code-repoffe2b06dbe2927a825ef93494a6ac34b27f58ecc) (Ginger Society Admin) feat: added rabbit mq deployment and service and addded pipeline cli installer script
	
chore:
 - [c9e858651b](https://github.com/ginger-society/infra-as-code-repoc9e858651beaaa3be5309b4de7ace78af7ca0d44) (Ginger Society Admin) chore: version bump to 0.21.0-nightly.0
	
## 0.15.0-nightly.0 - 2024-09-24
chore:
 - [7be0f233b2](https://github.com/ginger-society/infra-as-code-repo7be0f233b2e600b985b8ea894ea5966d3b9494c5) (Ginger Society Admin) chore: version bump to 0.15.0-nightly.0
	
feat:
 - [cd8bf4ded4](https://github.com/ginger-society/infra-as-code-repocd8bf4ded465a8e1cb4a186571ad39ebfadb61f9) (Ginger Society Admin) feat: updated metadata
	
## 0.14.0-nightly.0 - 2024-09-24
chore:
 - [d668b14354](https://github.com/ginger-society/infra-as-code-repod668b14354d145cdd7a61dd649e5eb0796b86fd3) (Ginger Society Admin) chore: version bump to 0.14.0-nightly.0
	
## 0.13.0-nightly.0 - 2024-09-23
chore:
 - [19c4766ac4](https://github.com/ginger-society/infra-as-code-repo19c4766ac4b1823bc1e63292a351a24e1f75e9aa) (Ginger Society Admin) chore: version bump to 0.13.0-nightly.0
	
## 0.12.0-nightly.0 - 2024-09-23
chore:
 - [44a4faa864](https://github.com/ginger-society/infra-as-code-repo44a4faa86413ff71ae6fbd9003726b10273ae310) (Ginger Society Admin) chore: version bump to 0.12.0-nightly.0
	
## 0.9.0-nightly.0 - 2024-09-23
chore:
 - [97c48af7db](https://github.com/ginger-society/infra-as-code-repo97c48af7db891ae19180b695c7def0d065a71b86) (Ginger Society Admin) chore: version bump to 0.9.0-nightly.0
	
## 0.8.0-nightly.0 - 2024-09-23
chore:
 - [ed6db7ab02](https://github.com/ginger-society/infra-as-code-repoed6db7ab02d6137c52af891642083e650c082076) (Ginger Society Admin) chore: version bump to 0.8.0-nightly.0
	
## 0.7.0-nightly.0 - 2024-09-23
chore:
 - [3a9342df6e](https://github.com/ginger-society/infra-as-code-repo3a9342df6e37804d2d21e49a15bc5d3d1f71004e) (Ginger Society Admin) chore: version bump to 0.7.0-nightly.0
	
## 0.6.0-nightly.0 - 2024-09-23
feat:
 - [cdba17f0d0](https://github.com/ginger-society/infra-as-code-repocdba17f0d08b4f80736d9bbdf90fd2e2014bc013) (Ginger Society Admin) feat: changed yatn to pnpm
	
 - [eadf11c548](https://github.com/ginger-society/infra-as-code-repoeadf11c548641e96280f58739fa957421202863a) (Ginger Society Admin) feat: fixing node version to 20
	
 - [47b3baa885](https://github.com/ginger-society/infra-as-code-repo47b3baa885e14874726dd41d8b55850c2e5cf46c) (Ginger Society Admin) feat: reverting version check comand
	
chore:
 - [53c481b568](https://github.com/ginger-society/infra-as-code-repo53c481b568d879af2135a2e3176c0d18fa0af174) (Ginger Society Admin) chore: version bump to 0.6.0-nightly.0
	
 - [54d8332e06](https://github.com/ginger-society/infra-as-code-repo54d8332e0632b4ea8e750c6f7c0865ab17782982) (Ginger Society Admin) chore: remobed openapi cli version comand
	
fix:
 - [270175a2d4](https://github.com/ginger-society/infra-as-code-repo270175a2d42289940a79608a1f31c437c94c78aa) (Ginger Society Admin) fix: minor
	
## 0.5.0-nightly.0 - 2024-09-09
chore:
 - [f655939ff4](https://github.com/ginger-society/infra-as-code-repof655939ff4810699437c160d6471557d2a29b651) (Ginger Society Admin) chore: version bump to 0.5.0-nightly.0
	
## 0.4.0-nightly.0 - 2024-09-09
chore:
 - [851ee9ccfe](https://github.com/ginger-society/infra-as-code-repo851ee9ccfe081451741baee4dffbecf7f75bee24) (Ginger Society Admin) chore: version bump to 0.4.0-nightly.0
	
## 0.3.0-nightly.0 - 2024-09-09
chore:
 - [dc29cbc500](https://github.com/ginger-society/infra-as-code-repodc29cbc500a72ca4967bc03e8bef67adae20f53e) (Ginger Society Admin) chore: version bump to 0.3.0-nightly.0
	
## 0.2.0-nightly.0 - 2024-09-09
first
 - [af7df1df94](https://github.com/ginger-society/infra-as-code-repoaf7df1df942b114a4a00e6323cc3b7eb4a889592) (py-react) first commit
	
chore:
 - [a52e337f1e](https://github.com/ginger-society/infra-as-code-repoa52e337f1e1250e2f24e2508c8ae4e758978dc20) (Ginger Society Admin) chore: version bump to 0.2.0-nightly.0
	
 - [9db78cf567](https://github.com/ginger-society/infra-as-code-repo9db78cf5673613e0a55fa33226c254e20bc54c83) (Ginger Society Admin) chore: cleanup
	
 - [08d6fdfac6](https://github.com/ginger-society/infra-as-code-repo08d6fdfac6f17d8d948fcf01028c3cd30e51cf1c) (Ginger Society Admin) chore: minor copy change in readme
	
 - [f90527bdf3](https://github.com/ginger-society/infra-as-code-repof90527bdf3af6e6e42502c040ceb4ed02118e713) (Ginger Society Admin) chore: refactored
	
fix:
 - [e306d11813](https://github.com/ginger-society/infra-as-code-repoe306d11813dbfbcb3ad2e03cd999b2821eda5682) (Ginger Society Admin) fix: typo
	
 - [2bfe3abd46](https://github.com/ginger-society/infra-as-code-repo2bfe3abd466b3374da0353d1dd3c8c0fa798b2d4) (Ginger Society Admin) fix: permission error for ginger-auth executable
	
 - [448bef1c98](https://github.com/ginger-society/infra-as-code-repo448bef1c98aaee65cdec46192a828d787fc4e1ad) (Ginger Society Admin) fix: pipeline
	
 - [e672d8fd28](https://github.com/ginger-society/infra-as-code-repoe672d8fd28b35fab74b8de1132791c45f83371a6) (Ginger Society Admin) fix: pipeline
	
 - [a8389487af](https://github.com/ginger-society/infra-as-code-repoa8389487afe80a2a87d306bc9a3b868e1dda48de) (Ginger Society Admin) fix: folder name correction
	
feat:
 - [84d492aeb3](https://github.com/ginger-society/infra-as-code-repo84d492aeb34550886a9984f02ef56f8a75c89e30) (Ginger Society Admin) feat: added changelot and releaser in git
	
 - [13b8e904d1](https://github.com/ginger-society/infra-as-code-repo13b8e904d1c00e376d8b9c189a3a101882817ce7) (Ginger Society Admin) feat: added rocket api dev container image
	
 - [c2a0f97f3c](https://github.com/ginger-society/infra-as-code-repoc2a0f97f3cd8447bd37d0bc76c9b2c6ba2e9b30c) (Ginger Society Admin) feat: added dev image for react vite
	
 - [412acb8616](https://github.com/ginger-society/infra-as-code-repo412acb86165bede2906bb6537b2f146932635ebe) (Ginger Society Admin) feat: added dev container image for vite react templates
	
 - [68de08892c](https://github.com/ginger-society/infra-as-code-repo68de08892ceaab3789f813fcca6cb05e01d3feef) (Ginger Society Admin) feat: updated builder image to use installer script
	
 - [023684ff28](https://github.com/ginger-society/infra-as-code-repo023684ff28db5d3d51b1243f0e560911d55b437c) (Ginger Society Admin) feat: added install all script for clis
	
 - [1221027656](https://github.com/ginger-society/infra-as-code-repo1221027656a18d44c19b0aecb20c945e5d2c12aa) (Ginger Society Admin) feat: updated script to use latest version from an api
	
 - [293ea286cd](https://github.com/ginger-society/infra-as-code-repo293ea286cd22989d308a4eaac08271a9d483f43e) (Ginger Society Admin) feat: added the installer script
	
 - [9a2221fa5f](https://github.com/ginger-society/infra-as-code-repo9a2221fa5fcf6e0a41bd406295df39ff429c109b) (Ginger Society Admin) feat: fixed vite builder
	
 - [a2f9e35d71](https://github.com/ginger-society/infra-as-code-repoa2f9e35d718ace7e9cbff67bbc5a546babb2dee1) (Ginger Society Admin) feat: updated docker file for rust rocket api
	
 - [0fc76abbad](https://github.com/ginger-society/infra-as-code-repo0fc76abbada313bd4160cecddf3d67bf03ddad4f) (Ginger Society Admin) feat: added docker file for builder image for react - vite SPA
	
 - [8f5e19f389](https://github.com/ginger-society/infra-as-code-repo8f5e19f389217f02338f2928ed537fe015201e71) (Ginger Society Admin) feat: added builder and runner for rust rocket api
	
 - [893e961ec1](https://github.com/ginger-society/infra-as-code-repo893e961ec18d870579f84f97a36165fde682010b) (Ginger Society Admin) feat: added build and upload scripts for rust clis
	
 - [c45c31035b](https://github.com/ginger-society/infra-as-code-repoc45c31035ba0998f3a218674b054e7c30775b617) (Ginger Society Admin) feat: updated image for metadata and iam service
	
 - [7b3ab002b7](https://github.com/ginger-society/infra-as-code-repo7b3ab002b7d73b9f86de1228b697610f2ee8f796) (Ginger Society Admin) feat: updated readme
	
 - [04e6d73266](https://github.com/ginger-society/infra-as-code-repo04e6d732660cd41e6a3f7b6f7833d0f2f58ce1a8) (Ginger Society Admin) feat: added iam service
	
 - [0b0d5cf119](https://github.com/ginger-society/infra-as-code-repo0b0d5cf119a88894a5b6084c810191638b2b2fcc) (Ginger Society Admin) feat: added metadata app
	
