  $ BH_ROOT=$TESTDIR/../../

Let's try a very simple mapping job (no chunking)

  $ bauhaus -o map -m -t ${BH_ROOT}test/data/lambdaAndEcoli.csv -w Mapping --chunks 0 generate
  Validation and input resolution succeeded.
  Runnable workflow written to directory "map"


  $ tree map
  map
  |-- build.ninja
  |-- condition-table.csv
  |-- log
  `-- run.sh
  
  1 directory, 3 files


  $ cat map/condition-table.csv
  Condition,RunCode,ReportsFolder,Genome
  Lambda,3150128-0001,,lambdaNEB
  Lambda,3150128-0002,,lambdaNEB
  Ecoli,3150122-0001,,ecoliK12_pbi_March2013
  Ecoli,3150122-0002,,ecoliK12_pbi_March2013


  $ cat map/build.ninja
  # Variables
  ncpus = 8
  scratchDir = /scratch
  grid = qsub -sync y -cwd -V -b y -e log -o log
  gridSMP = $grid -pe smp $ncpus
  
  # Rules
  rule copySubreadsDataset
    command = $grid dataset create $out $in
  
  rule map
    command = $gridSMP pbalign --tmpDir=$scratchDir --nproc $ncpus $in $
        $reference $out
  
  rule mergeDatasetsForCondition
    command = $grid dataset merge $out $in
  
  
  # Build targets
  build Ecoli/subreads/m54011_160305_235923.subreadset.xml: $
      copySubreadsDataset $
      /pbi/collections/315/3150122/r54011_20160305_235615/1_A01/m54011_160305_235923.subreadset.xml
  
  build Ecoli/subreads/m54011_160306_050740.subreadset.xml: $
      copySubreadsDataset $
      /pbi/collections/315/3150122/r54011_20160305_235615/2_B01/m54011_160306_050740.subreadset.xml
  
  build Ecoli/mapping/m54011_160305_235923.alignmentset.xml: map $
      Ecoli/subreads/m54011_160305_235923.subreadset.xml
    reference = $
        /mnt/secondary/iSmrtanalysis/current/common/references/ecoliK12_pbi_March2013/sequence/ecoliK12_pbi_March2013.fasta
  
  build Ecoli/mapping/m54011_160306_050740.alignmentset.xml: map $
      Ecoli/subreads/m54011_160306_050740.subreadset.xml
    reference = $
        /mnt/secondary/iSmrtanalysis/current/common/references/ecoliK12_pbi_March2013/sequence/ecoliK12_pbi_March2013.fasta
  
  build Ecoli/mapping/all_movies.alignmentset.xml: mergeDatasetsForCondition $
      Ecoli/mapping/m54011_160305_235923.alignmentset.xml $
      Ecoli/mapping/m54011_160306_050740.alignmentset.xml
  
  build Lambda/subreads/m54008_160308_002050.subreadset.xml: $
      copySubreadsDataset $
      /pbi/collections/315/3150128/r54008_20160308_001811/1_A01/m54008_160308_002050.subreadset.xml
  
  build Lambda/subreads/m54008_160308_053311.subreadset.xml: $
      copySubreadsDataset $
      /pbi/collections/315/3150128/r54008_20160308_001811/2_B01/m54008_160308_053311.subreadset.xml
  
  build Lambda/mapping/m54008_160308_002050.alignmentset.xml: map $
      Lambda/subreads/m54008_160308_002050.subreadset.xml
    reference = $
        /mnt/secondary/iSmrtanalysis/current/common/references/lambdaNEB/sequence/lambdaNEB.fasta
  
  build Lambda/mapping/m54008_160308_053311.alignmentset.xml: map $
      Lambda/subreads/m54008_160308_053311.subreadset.xml
    reference = $
        /mnt/secondary/iSmrtanalysis/current/common/references/lambdaNEB/sequence/lambdaNEB.fasta
  
  build Lambda/mapping/all_movies.alignmentset.xml: mergeDatasetsForCondition $
      Lambda/mapping/m54008_160308_002050.alignmentset.xml $
      Lambda/mapping/m54008_160308_053311.alignmentset.xml
  


Now try with chunking

  $ bauhaus -o chunkedMapping -m -t ${BH_ROOT}test/data/lambdaAndEcoli.csv -w Mapping --chunks 2 generate
  Validation and input resolution succeeded.
  Runnable workflow written to directory "chunkedMapping"


  $ cat chunkedMapping/build.ninja
  # Variables
  ncpus = 8
  scratchDir = /scratch
  grid = qsub -sync y -cwd -V -b y -e log -o log
  gridSMP = $grid -pe smp $ncpus
  
  # Rules
  rule copySubreadsDataset
    command = $grid dataset create $out $in
  
  rule map
    command = $gridSMP pbalign  --tmpDir=$scratchDir --nproc $ncpus $in $
        $reference $out
  
  rule splitByZmw
    command = $grid dataset split --zmws --targetSize 1 --chunks 2 --outdir $
        $outdir $in
  
  rule mergeDatasetsForCondition
    command = $grid dataset merge $out $in
  
  
  # Build targets
  build Ecoli/subreads/m54011_160305_235923.subreadset.xml: $
      copySubreadsDataset $
      /pbi/collections/315/3150122/r54011_20160305_235615/1_A01/m54011_160305_235923.subreadset.xml
  
  build Ecoli/subreads/m54011_160306_050740.subreadset.xml: $
      copySubreadsDataset $
      /pbi/collections/315/3150122/r54011_20160305_235615/2_B01/m54011_160306_050740.subreadset.xml
  
  build Ecoli/subreads_chunks/m54011_160305_235923.chunk0.subreadset.xml $
      Ecoli/subreads_chunks/m54011_160305_235923.chunk1.subreadset.xml: $
      splitByZmw Ecoli/subreads/m54011_160305_235923.subreadset.xml
    outdir = Ecoli/subreads_chunks
  
  build Ecoli/mapping_chunks/m54011_160305_235923.chunk0.alignmentset.xml: $
      map Ecoli/subreads_chunks/m54011_160305_235923.chunk0.subreadset.xml
    reference = $
        /mnt/secondary/iSmrtanalysis/current/common/references/ecoliK12_pbi_March2013/sequence/ecoliK12_pbi_March2013.fasta
  
  build Ecoli/mapping_chunks/m54011_160305_235923.chunk1.alignmentset.xml: $
      map Ecoli/subreads_chunks/m54011_160305_235923.chunk1.subreadset.xml
    reference = $
        /mnt/secondary/iSmrtanalysis/current/common/references/ecoliK12_pbi_March2013/sequence/ecoliK12_pbi_March2013.fasta
  
  build Ecoli/subreads_chunks/m54011_160306_050740.chunk0.subreadset.xml $
      Ecoli/subreads_chunks/m54011_160306_050740.chunk1.subreadset.xml: $
      splitByZmw Ecoli/subreads/m54011_160306_050740.subreadset.xml
    outdir = Ecoli/subreads_chunks
  
  build Ecoli/mapping_chunks/m54011_160306_050740.chunk0.alignmentset.xml: $
      map Ecoli/subreads_chunks/m54011_160306_050740.chunk0.subreadset.xml
    reference = $
        /mnt/secondary/iSmrtanalysis/current/common/references/ecoliK12_pbi_March2013/sequence/ecoliK12_pbi_March2013.fasta
  
  build Ecoli/mapping_chunks/m54011_160306_050740.chunk1.alignmentset.xml: $
      map Ecoli/subreads_chunks/m54011_160306_050740.chunk1.subreadset.xml
    reference = $
        /mnt/secondary/iSmrtanalysis/current/common/references/ecoliK12_pbi_March2013/sequence/ecoliK12_pbi_March2013.fasta
  
  build Ecoli/mapping/all_movies.alignmentset.xml: mergeDatasetsForCondition $
      Ecoli/mapping_chunks/m54011_160305_235923.chunk0.alignmentset.xml $
      Ecoli/mapping_chunks/m54011_160305_235923.chunk1.alignmentset.xml $
      Ecoli/mapping_chunks/m54011_160306_050740.chunk0.alignmentset.xml $
      Ecoli/mapping_chunks/m54011_160306_050740.chunk1.alignmentset.xml
  
  build Lambda/subreads/m54008_160308_002050.subreadset.xml: $
      copySubreadsDataset $
      /pbi/collections/315/3150128/r54008_20160308_001811/1_A01/m54008_160308_002050.subreadset.xml
  
  build Lambda/subreads/m54008_160308_053311.subreadset.xml: $
      copySubreadsDataset $
      /pbi/collections/315/3150128/r54008_20160308_001811/2_B01/m54008_160308_053311.subreadset.xml
  
  build Lambda/subreads_chunks/m54008_160308_002050.chunk0.subreadset.xml $
      Lambda/subreads_chunks/m54008_160308_002050.chunk1.subreadset.xml: $
      splitByZmw Lambda/subreads/m54008_160308_002050.subreadset.xml
    outdir = Lambda/subreads_chunks
  
  build Lambda/mapping_chunks/m54008_160308_002050.chunk0.alignmentset.xml: $
      map Lambda/subreads_chunks/m54008_160308_002050.chunk0.subreadset.xml
    reference = $
        /mnt/secondary/iSmrtanalysis/current/common/references/lambdaNEB/sequence/lambdaNEB.fasta
  
  build Lambda/mapping_chunks/m54008_160308_002050.chunk1.alignmentset.xml: $
      map Lambda/subreads_chunks/m54008_160308_002050.chunk1.subreadset.xml
    reference = $
        /mnt/secondary/iSmrtanalysis/current/common/references/lambdaNEB/sequence/lambdaNEB.fasta
  
  build Lambda/subreads_chunks/m54008_160308_053311.chunk0.subreadset.xml $
      Lambda/subreads_chunks/m54008_160308_053311.chunk1.subreadset.xml: $
      splitByZmw Lambda/subreads/m54008_160308_053311.subreadset.xml
    outdir = Lambda/subreads_chunks
  
  build Lambda/mapping_chunks/m54008_160308_053311.chunk0.alignmentset.xml: $
      map Lambda/subreads_chunks/m54008_160308_053311.chunk0.subreadset.xml
    reference = $
        /mnt/secondary/iSmrtanalysis/current/common/references/lambdaNEB/sequence/lambdaNEB.fasta
  
  build Lambda/mapping_chunks/m54008_160308_053311.chunk1.alignmentset.xml: $
      map Lambda/subreads_chunks/m54008_160308_053311.chunk1.subreadset.xml
    reference = $
        /mnt/secondary/iSmrtanalysis/current/common/references/lambdaNEB/sequence/lambdaNEB.fasta
  
  build Lambda/mapping/all_movies.alignmentset.xml: mergeDatasetsForCondition $
      Lambda/mapping_chunks/m54008_160308_002050.chunk0.alignmentset.xml $
      Lambda/mapping_chunks/m54008_160308_002050.chunk1.alignmentset.xml $
      Lambda/mapping_chunks/m54008_160308_053311.chunk0.alignmentset.xml $
      Lambda/mapping_chunks/m54008_160308_053311.chunk1.alignmentset.xml
  
