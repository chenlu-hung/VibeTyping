#!/usr/bin/env ruby
# Generate VibeTyping.xcodeproj manually
# Run: ruby generate_project.rb

require 'fileutils'
require 'securerandom'

# Helper to generate Xcode-style UUIDs (24 hex chars)
def xcode_uuid
  SecureRandom.hex(12).upcase
end

proj_dir = File.join(__dir__, 'VibeTyping.xcodeproj')
FileUtils.mkdir_p(proj_dir)

# Collect all Swift source files
source_dir = File.join(__dir__, 'VibeTyping')
swift_files = Dir.glob(File.join(source_dir, '**', '*.swift')).sort

# Assign UUIDs to each file
file_refs = {}
build_files = {}

swift_files.each do |path|
  rel_path = path.sub("#{__dir__}/", '')
  file_ref_id = xcode_uuid
  build_file_id = xcode_uuid
  file_refs[rel_path] = file_ref_id
  build_files[rel_path] = build_file_id
end

# Additional resource files
info_plist_path = 'VibeTyping/Resources/Info.plist'
info_plist_ref = xcode_uuid

entitlements_path = 'VibeTyping/Resources/VibeTyping.entitlements'
entitlements_ref = xcode_uuid

# Group UUIDs
root_group_id = xcode_uuid
app_group_id = xcode_uuid
input_method_group_id = xcode_uuid
audio_group_id = xcode_uuid
transcription_group_id = xcode_uuid
punctuation_group_id = xcode_uuid
llm_group_id = xcode_uuid
ui_group_id = xcode_uuid
settings_group_id = xcode_uuid
resources_group_id = xcode_uuid
vibetyping_group_id = xcode_uuid
frameworks_group_id = xcode_uuid
products_group_id = xcode_uuid

# Target and config UUIDs
project_id = xcode_uuid
target_id = xcode_uuid
product_ref_id = xcode_uuid
sources_phase_id = xcode_uuid
frameworks_phase_id = xcode_uuid
resources_phase_id = xcode_uuid
copy_phase_id = xcode_uuid

debug_config_id = xcode_uuid
release_config_id = xcode_uuid
project_debug_config_id = xcode_uuid
project_release_config_id = xcode_uuid
target_config_list_id = xcode_uuid
project_config_list_id = xcode_uuid

# WhisperKit package UUIDs
package_ref_id = xcode_uuid
package_product_dep_id = xcode_uuid
package_product_ref_id = xcode_uuid
package_build_file_id = xcode_uuid

# sherpa-onnx package UUIDs (CT-Transformer punctuation model runtime)
sherpa_ref_id = xcode_uuid
sherpa_product_ref_id = xcode_uuid
sherpa_build_file_id = xcode_uuid

# Framework references
imk_framework_ref = xcode_uuid
imk_build_file = xcode_uuid
avfoundation_framework_ref = xcode_uuid
avfoundation_build_file = xcode_uuid
carbon_framework_ref = xcode_uuid
carbon_build_file = xcode_uuid

# Categorize files by group
groups = {
  'App' => [], 'InputMethod' => [], 'Audio' => [], 'Transcription' => [],
  'Punctuation' => [], 'LLM' => [], 'UI' => [], 'Settings' => []
}

file_refs.each do |path, _|
  groups.each do |group_name, files|
    if path.include?("/#{group_name}/")
      files << path
    end
  end
end

group_ids = {
  'App' => app_group_id,
  'InputMethod' => input_method_group_id,
  'Audio' => audio_group_id,
  'Transcription' => transcription_group_id,
  'Punctuation' => punctuation_group_id,
  'LLM' => llm_group_id,
  'UI' => ui_group_id,
  'Settings' => settings_group_id,
}

# Build the pbxproj content
pbx = <<~PBX
// !$*UTF8*$!
{
	archiveVersion = 1;
	classes = {
	};
	objectVersion = 56;
	objects = {

/* Begin PBXBuildFile section */
PBX

# Source build files
build_files.each do |path, bf_id|
  fr_id = file_refs[path]
  name = File.basename(path)
  pbx += "\t\t#{bf_id} /* #{name} in Sources */ = {isa = PBXBuildFile; fileRef = #{fr_id} /* #{name} */; };\n"
end

# Framework build files
pbx += "\t\t#{imk_build_file} /* InputMethodKit.framework in Frameworks */ = {isa = PBXBuildFile; fileRef = #{imk_framework_ref} /* InputMethodKit.framework */; };\n"
pbx += "\t\t#{avfoundation_build_file} /* AVFoundation.framework in Frameworks */ = {isa = PBXBuildFile; fileRef = #{avfoundation_framework_ref} /* AVFoundation.framework */; };\n"
pbx += "\t\t#{carbon_build_file} /* Carbon.framework in Frameworks */ = {isa = PBXBuildFile; fileRef = #{carbon_framework_ref} /* Carbon.framework */; };\n"
pbx += "\t\t#{package_build_file_id} /* WhisperKit in Frameworks */ = {isa = PBXBuildFile; productRef = #{package_product_ref_id} /* WhisperKit */; };\n"
pbx += "\t\t#{sherpa_build_file_id} /* sherpa-onnx in Frameworks */ = {isa = PBXBuildFile; productRef = #{sherpa_product_ref_id} /* sherpa-onnx */; };\n"

pbx += <<~PBX
/* End PBXBuildFile section */

/* Begin PBXFileReference section */
PBX

# Source file references
file_refs.each do |path, fr_id|
  name = File.basename(path)
  pbx += "\t\t#{fr_id} /* #{name} */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = \"#{name}\"; sourceTree = \"<group>\"; };\n"
end

# Info.plist and entitlements
pbx += "\t\t#{info_plist_ref} /* Info.plist */ = {isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = \"Info.plist\"; sourceTree = \"<group>\"; };\n"
pbx += "\t\t#{entitlements_ref} /* VibeTyping.entitlements */ = {isa = PBXFileReference; lastKnownFileType = text.plist.entitlements; path = \"VibeTyping.entitlements\"; sourceTree = \"<group>\"; };\n"

# Product reference
pbx += "\t\t#{product_ref_id} /* VibeTyping.app */ = {isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = VibeTyping.app; sourceTree = BUILT_PRODUCTS_DIR; };\n"

# Framework references
pbx += "\t\t#{imk_framework_ref} /* InputMethodKit.framework */ = {isa = PBXFileReference; lastKnownFileType = wrapper.framework; name = InputMethodKit.framework; path = System/Library/Frameworks/InputMethodKit.framework; sourceTree = SDKROOT; };\n"
pbx += "\t\t#{avfoundation_framework_ref} /* AVFoundation.framework */ = {isa = PBXFileReference; lastKnownFileType = wrapper.framework; name = AVFoundation.framework; path = System/Library/Frameworks/AVFoundation.framework; sourceTree = SDKROOT; };\n"
pbx += "\t\t#{carbon_framework_ref} /* Carbon.framework */ = {isa = PBXFileReference; lastKnownFileType = wrapper.framework; name = Carbon.framework; path = System/Library/Frameworks/Carbon.framework; sourceTree = SDKROOT; };\n"

pbx += <<~PBX
/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
		#{frameworks_phase_id} /* Frameworks */ = {
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
				#{imk_build_file} /* InputMethodKit.framework in Frameworks */,
				#{avfoundation_build_file} /* AVFoundation.framework in Frameworks */,
				#{carbon_build_file} /* Carbon.framework in Frameworks */,
				#{package_build_file_id} /* WhisperKit in Frameworks */,
				#{sherpa_build_file_id} /* sherpa-onnx in Frameworks */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
		#{root_group_id} = {
			isa = PBXGroup;
			children = (
				#{vibetyping_group_id} /* VibeTyping */,
				#{frameworks_group_id} /* Frameworks */,
				#{products_group_id} /* Products */,
			);
			sourceTree = "<group>";
		};
		#{products_group_id} /* Products */ = {
			isa = PBXGroup;
			children = (
				#{product_ref_id} /* VibeTyping.app */,
			);
			name = Products;
			sourceTree = "<group>";
		};
		#{frameworks_group_id} /* Frameworks */ = {
			isa = PBXGroup;
			children = (
				#{imk_framework_ref} /* InputMethodKit.framework */,
				#{avfoundation_framework_ref} /* AVFoundation.framework */,
				#{carbon_framework_ref} /* Carbon.framework */,
			);
			name = Frameworks;
			sourceTree = "<group>";
		};
		#{vibetyping_group_id} /* VibeTyping */ = {
			isa = PBXGroup;
			children = (
				#{app_group_id} /* App */,
				#{input_method_group_id} /* InputMethod */,
				#{audio_group_id} /* Audio */,
				#{transcription_group_id} /* Transcription */,
				#{punctuation_group_id} /* Punctuation */,
				#{llm_group_id} /* LLM */,
				#{ui_group_id} /* UI */,
				#{settings_group_id} /* Settings */,
				#{resources_group_id} /* Resources */,
			);
			path = VibeTyping;
			sourceTree = "<group>";
		};
PBX

# Sub-groups for each category
group_ids.each do |group_name, gid|
  children = groups[group_name].map { |p| "\t\t\t\t#{file_refs[p]} /* #{File.basename(p)} */," }.join("\n")
  pbx += <<~PBX
		#{gid} /* #{group_name} */ = {
			isa = PBXGroup;
			children = (
#{children}
			);
			path = #{group_name};
			sourceTree = "<group>";
		};
PBX
end

# Resources group
pbx += <<~PBX
		#{resources_group_id} /* Resources */ = {
			isa = PBXGroup;
			children = (
				#{info_plist_ref} /* Info.plist */,
				#{entitlements_ref} /* VibeTyping.entitlements */,
			);
			path = Resources;
			sourceTree = "<group>";
		};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
		#{target_id} /* VibeTyping */ = {
			isa = PBXNativeTarget;
			buildConfigurationList = #{target_config_list_id} /* Build configuration list for PBXNativeTarget "VibeTyping" */;
			buildPhases = (
				#{sources_phase_id} /* Sources */,
				#{frameworks_phase_id} /* Frameworks */,
				#{resources_phase_id} /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
			);
			name = VibeTyping;
			packageProductDependencies = (
				#{package_product_ref_id} /* WhisperKit */,
				#{sherpa_product_ref_id} /* sherpa-onnx */,
			);
			productName = VibeTyping;
			productReference = #{product_ref_id} /* VibeTyping.app */;
			productType = "com.apple.product-type.application";
		};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
		#{project_id} /* Project object */ = {
			isa = PBXProject;
			attributes = {
				BuildIndependentTargetsInParallel = 1;
				LastSwiftUpdateCheck = 1540;
				LastUpgradeCheck = 1540;
			};
			buildConfigurationList = #{project_config_list_id} /* Build configuration list for PBXProject "VibeTyping" */;
			compatibilityVersion = "Xcode 14.0";
			developmentRegion = "zh-Hant";
			hasScannedForEncodings = 0;
			knownRegions = (
				"zh-Hant",
				en,
				Base,
			);
			mainGroup = #{root_group_id};
			packageReferences = (
				#{package_ref_id} /* XCRemoteSwiftPackageReference "WhisperKit" */,
				#{sherpa_ref_id} /* XCRemoteSwiftPackageReference "sherpa-onnx" */,
			);
			productRefGroup = #{products_group_id} /* Products */;
			projectDirPath = "";
			projectRoot = "";
			targets = (
				#{target_id} /* VibeTyping */,
			);
		};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
		#{resources_phase_id} /* Resources */ = {
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
		#{sources_phase_id} /* Sources */ = {
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
PBX

build_files.each do |path, bf_id|
  name = File.basename(path)
  pbx += "\t\t\t\t#{bf_id} /* #{name} in Sources */,\n"
end

pbx += <<~PBX
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXSourcesBuildPhase section */

/* Begin XCBuildConfiguration section */
		#{project_debug_config_id} /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = dwarf;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_TESTABILITY = YES;
				GCC_DYNAMIC_NO_PIC = NO;
				GCC_OPTIMIZATION_LEVEL = 0;
				GCC_PREPROCESSOR_DEFINITIONS = (
					"DEBUG=1",
					"$(inherited)",
				);
				MACOSX_DEPLOYMENT_TARGET = 14.0;
				MTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
				ONLY_ACTIVE_ARCH = YES;
				SDKROOT = macosx;
				SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;
				SWIFT_OPTIMIZATION_LEVEL = "-Onone";
			};
			name = Debug;
		};
		#{project_release_config_id} /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
				ENABLE_NS_ASSERTIONS = NO;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				MACOSX_DEPLOYMENT_TARGET = 14.0;
				MTL_ENABLE_DEBUG_INFO = NO;
				SDKROOT = macosx;
				SWIFT_COMPILATION_MODE = wholemodule;
				SWIFT_OPTIMIZATION_LEVEL = "-O";
			};
			name = Release;
		};
		#{debug_config_id} /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				CODE_SIGN_ENTITLEMENTS = VibeTyping/Resources/VibeTyping.entitlements;
				CODE_SIGN_STYLE = Automatic;
				COMBINE_HIDPI_IMAGES = YES;
				CURRENT_PROJECT_VERSION = 1;
				GENERATE_INFOPLIST_FILE = NO;
				INFOPLIST_FILE = VibeTyping/Resources/Info.plist;
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.vibetyping.inputmethod.VibeTyping;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
			};
			name = Debug;
		};
		#{release_config_id} /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				CODE_SIGN_ENTITLEMENTS = VibeTyping/Resources/VibeTyping.entitlements;
				CODE_SIGN_STYLE = Automatic;
				COMBINE_HIDPI_IMAGES = YES;
				CURRENT_PROJECT_VERSION = 1;
				GENERATE_INFOPLIST_FILE = NO;
				INFOPLIST_FILE = VibeTyping/Resources/Info.plist;
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.vibetyping.inputmethod.VibeTyping;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
			};
			name = Release;
		};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
		#{project_config_list_id} /* Build configuration list for PBXProject "VibeTyping" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				#{project_debug_config_id} /* Debug */,
				#{project_release_config_id} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
		#{target_config_list_id} /* Build configuration list for PBXNativeTarget "VibeTyping" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				#{debug_config_id} /* Debug */,
				#{release_config_id} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
/* End XCConfigurationList section */

/* Begin XCRemoteSwiftPackageReference section */
		#{package_ref_id} /* XCRemoteSwiftPackageReference "WhisperKit" */ = {
			isa = XCRemoteSwiftPackageReference;
			repositoryURL = "https://github.com/argmaxinc/WhisperKit.git";
			requirement = {
				kind = upToNextMajorVersion;
				minimumVersion = 0.9.0;
			};
		};
		#{sherpa_ref_id} /* XCRemoteSwiftPackageReference "sherpa-onnx" */ = {
			isa = XCRemoteSwiftPackageReference;
			repositoryURL = "https://github.com/k2-fsa/sherpa-onnx.git";
			requirement = {
				kind = upToNextMinorVersion;
				minimumVersion = 1.13.7;
			};
		};
/* End XCRemoteSwiftPackageReference section */

/* Begin XCSwiftPackageProductDependency section */
		#{package_product_ref_id} /* WhisperKit */ = {
			isa = XCSwiftPackageProductDependency;
			package = #{package_ref_id} /* XCRemoteSwiftPackageReference "WhisperKit" */;
			productName = WhisperKit;
		};
		#{sherpa_product_ref_id} /* sherpa-onnx */ = {
			isa = XCSwiftPackageProductDependency;
			package = #{sherpa_ref_id} /* XCRemoteSwiftPackageReference "sherpa-onnx" */;
			productName = "sherpa-onnx";
		};
/* End XCSwiftPackageProductDependency section */

	};
	rootObject = #{project_id} /* Project object */;
}
PBX

# Write pbxproj
File.write(File.join(proj_dir, 'project.pbxproj'), pbx)

# Write xcscheme
schemes_dir = File.join(proj_dir, 'xcshareddata', 'xcschemes')
FileUtils.mkdir_p(schemes_dir)

scheme = <<~SCHEME
<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "1540"
   version = "1.7">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "#{target_id}"
               BuildableName = "VibeTyping.app"
               BlueprintName = "VibeTyping"
               ReferencedContainer = "container:VibeTyping.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES">
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "#{target_id}"
            BuildableName = "VibeTyping.app"
            BlueprintName = "VibeTyping"
            ReferencedContainer = "container:VibeTyping.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Release"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "#{target_id}"
            BuildableName = "VibeTyping.app"
            BlueprintName = "VibeTyping"
            ReferencedContainer = "container:VibeTyping.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
SCHEME

File.write(File.join(schemes_dir, 'VibeTyping.xcscheme'), scheme)

puts "✅ Generated VibeTyping.xcodeproj successfully!"
puts "   Source files: #{swift_files.length}"
puts "   Open with: open VibeTyping.xcodeproj"
