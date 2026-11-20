# Foosball Table — licensed model attribution

**Model:** Foosball table
**Creator:** 3D Content Online (Sketchfab user hknoblauch)
**Original:** https://sketchfab.com/3d-models/foosball-table-5f70863c2cf74e99ad084a493209dbac
**License declared by the uploaded GLB:** Creative Commons Attribution 4.0 International (CC BY 4.0)
**License URL:** https://creativecommons.org/licenses/by/4.0/
**Local source filename:** foosball_table (2).glb
**Source SHA-256:** 6234047d83db0df64a7d5f7ef5044432b7e6f144e3b272019f546f6a2e44174

The source is **CC BY** rather than the previous VERTX3D source (which
prohibited redistribution). This model may be redistributed and modified under
CC BY terms with credit, a link to the license and an indication of changes.
Do not remove the attribution when publishing or shipping the game.

**Modifications in FoosballPhysicsLab:** The offline importer groups 103 source
mesh primitives into eight independently controlled rod assemblies, reuses
the original blue/red player mesh geometry to produce the game's 1-2-5-3
formation, remaps the model's coordinates and material color values, then
renders it through LÖVE's own GPU perspective/depth pipeline. An original
low-poly sphere is generated for the game's physically simulated ball.

To **keep the original GLB in the Git repository**, add the user-provided
CC BY binary here as `assets/models/foosball_table.glb`. Unlike the previous
restricted VERTX3D archive, the author-stated CC BY license permits this
with the attribution above. GitHub will then store the original source
along with its credits. Do not replace it with a Marble version: the two
Marble Foosball uploads are CC BY-NC and would restrict commercial use.

The repository script `tools/import_foosball_glb_ccby.py` converts this
source to `local_assets/3d/` locally, without needing to commit the large
generated vertex buffers. No GLB download or other third-party data is hidden
in `main.lua`.
