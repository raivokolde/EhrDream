docker build -t docker.synapse.org/syn21035092/dummy:0.3 Docker/V0.2/

docker run -v ~/Raivo/TartuProjects/EhrDream/CodeData/training_fastlane:/train:ro -v ~/Raivo/TartuProjects/EhrDream/Docker/V0.2/scratch/:/scratch:rw -v ~/Raivo/TartuProjects/EhrDream/Docker/V0.2/model/:/model:rw docker.synapse.org/syn21035092/dummy:0.3  bash /app/train.sh

docker run -v ~/Raivo/TartuProjects/EhrDream/CodeData/evaluation_fastlane:/infer:ro -v ~/Raivo/TartuProjects/EhrDream/Docker/V0.2/scratch/:/scratch:rw -v ~/Raivo/TartuProjects/EhrDream/Docker/V0.2/model/:/model:rw  -v ~/Raivo/TartuProjects/EhrDream/Docker/V0.2/output/:/output:rw docker.synapse.org/syn21035092/dummy:0.3  bash /app/infer.sh


docker login docker.synapse.org
docker push docker.synapse.org/syn21035092/dummy:0.3