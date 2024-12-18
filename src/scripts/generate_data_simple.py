import math
import random


class Entries:
    def __init__(self, name: str, entry_count: int):
        self.name = name
        self.entries = [None] * entry_count

    def write_to_file(self):

        fname = "src/data/simple/{}.in".format(self.name)

        f = open(fname, "w")
        f.write(str(len(self.entries)) + "\n")

        for i in range(len(self.entries)):
            entry = self.entries[i]
            f.write(str(entry) + "\n")
            pass

        f.close()

    @staticmethod
    def generate_entries(fname: str, entry_count: int, dep_cnt_low: int, dep_cnt_high: int) -> "Entries":
        entries = Entries(fname, entry_count)

        for i in range(entry_count):
            entries.entries[i] = Entry.generate_entry(i, dep_cnt_low, dep_cnt_high)

        return entries


class Entry:
    def __init__(self, index: int, dep_cnt_attempts: int):
        self.index = index
        self.dep_cnt_attempts = dep_cnt_attempts
        self.dependencies = list()  # [None] * self.dependency_count_high

    def generate_random_dependencies(self):

        if self.index == 0:
            return

        for i in range(self.dep_cnt_attempts):

            new_dep = random.randint(0, self.index - 1)

            if new_dep not in self.dependencies:
                self.dependencies.append(new_dep)

    def __str__(self):
        res = str(len(self.dependencies))

        for dep in self.dependencies:
            res += " {}".format(str(dep))

        return res

    @staticmethod
    def generate_entry(index: int, dep_cnt_low: int, dep_cnt_high: int) -> "Entry":
        dep_cnt_attempts = random.randint(dep_cnt_low, dep_cnt_high)

        entry = Entry(index, dep_cnt_attempts)
        entry.generate_random_dependencies()

        return entry


def main():
    entry_count = 65536

    # TODO: Genertate data where every node is dependent on the previous node
    # TODO: Genertate data where every node is dependent on every node from the prior "level"

    i = 16
    Entries.generate_entries("easy", entry_count, i, i*2).write_to_file()
    i *= 2
    Entries.generate_entries("medium", entry_count, i, i*2).write_to_file()
    i *= 2
    Entries.generate_entries("hard", entry_count, i, i*2).write_to_file()
    i *= 2
    Entries.generate_entries("impossible", entry_count, i, i*2).write_to_file()


if __name__ == "__main__":
    main()
