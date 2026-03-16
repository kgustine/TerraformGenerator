package org.terraform.main;

import org.jetbrains.annotations.NotNull;
import org.terraform.data.TerraformWorld;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardOpenOption;
import java.time.Instant;

public final class StructureSpawnLogger {

    private static final Object lock = new Object();
    private static final String FILE_NAME = "structure-spawns.csv";

    private StructureSpawnLogger() {}

    public static void logSpawn(@NotNull TerraformWorld tw,
                                @NotNull String structureName,
                                int chunkX,
                                int chunkZ,
                                int blockX,
                                int blockY,
                                int blockZ)
    {
        TerraformGeneratorPlugin plugin = TerraformGeneratorPlugin.get();
        if (plugin == null) {
            return;
        }

        Path out = plugin.getDataFolder().toPath().resolve(FILE_NAME);
        String line = String.join(",",
                Instant.now().toString(),
                sanitize(tw.getName()),
                sanitize(structureName),
                Integer.toString(chunkX),
                Integer.toString(chunkZ),
                Integer.toString(blockX),
                Integer.toString(blockY),
                Integer.toString(blockZ)
        ) + System.lineSeparator();

        synchronized (lock) {
            try {
                Files.createDirectories(out.getParent());
                if (Files.notExists(out)) {
                    String header = "timestamp,world,structure,chunk_x,chunk_z,block_x,block_y,block_z" + System.lineSeparator();
                    Files.writeString(out,
                            header,
                            StandardCharsets.UTF_8,
                            StandardOpenOption.CREATE,
                            StandardOpenOption.APPEND
                    );
                }
                Files.writeString(out,
                        line,
                        StandardCharsets.UTF_8,
                        StandardOpenOption.CREATE,
                        StandardOpenOption.APPEND
                );
            }
            catch (IOException e) {
                TerraformGeneratorPlugin.logger.error("Failed to write structure spawn log: " + e.getMessage());
            }
        }
    }

    private static @NotNull String sanitize(@NotNull String in) {
        return in.replace(",", "_");
    }
}
