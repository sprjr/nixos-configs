{
  config,
  pkgs,
  lib,
  ...
}:

let
  cuda = pkgs.cudaPackages_13_0;

  cudaBindings = pkgs.python3Packages.cuda-bindings.override {
    cudaPackages = cuda;
  };

  torchCuda = pkgs.python3Packages.torch-bin.override {
    cudaPackages = cuda;
    cuda-bindings = cudaBindings;
  };

  pythonCuda = pkgs.python3.override {
    self = pythonCuda;
    packageOverrides = _: prev: {
      cuda-bindings = cudaBindings;
      torch = torchCuda;
      tensorboardx = prev.tensorboardx.overridePythonAttrs (_: { doCheck = false; });
    };
  };

  piperTrain = pkgs.piper-tts.override {
    python3Packages = pythonCuda.pkgs;
  };

  piperTrainEnv = pythonCuda.withPackages (_: [ piperTrain ]);

  piper-train = pkgs.writeShellApplication {
    name = "piper-train";
    runtimeInputs = [ piperTrainEnv ];
    text = ''
      export LD_LIBRARY_PATH="/run/opengl-driver/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
      exec python3 -m piper.train "$@"
    '';
  };
in
{
  environment.systemPackages = [
    piperTrainEnv
    piper-train
  ];
}
