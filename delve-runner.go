package main

import (
	"bufio"
	"flag"
	"fmt"
	"io"
	"log"
	"os"
	"os/exec"
	"strings"
)

var (
	connect = flag.Bool("connect", false, "Connect to the running dlv instance")
	test    = flag.String("test", "", "Start debugging test `NAME`")

	initFile = flag.String("init", "init.txt", "Init file name")
)

func main() {
	flag.Parse()

	var err error
	var lc io.Closer

	if lc, err = initLog(); err != nil {
		log.Fatal(err)
	}
	defer lc.Close()

	var args = []string{"--init", *initFile, "--allow-non-terminal-interactive"}

	if *connect {
		args = append(args, "connect", "127.0.0.1:8077")
		fmt.Println("message: connecting to dlv 127.0.0.1:8077")
	} else if *test != "" {
		args = append(args, "test", "--", "-test.run", *test)
		fmt.Println("message: starting dlv test -- -test.run", *test)
	} else {
		args = append(args, "debug")
		fmt.Println("message: starting dlv debug")
	}

	cmd := exec.Command("dlv", args...)

	stdin, err := cmd.StdinPipe()
	if err != nil {
		log.Fatal(err)
	}
	stdout, err := cmd.StdoutPipe()
	if err != nil {
		log.Fatal(err)
	}

	if err := cmd.Start(); err != nil {
		log.Fatal(err)
	}

	in := bufio.NewReader(os.Stdin)
	out := bufio.NewReader(stdout)

	var dcommand string

	fmt.Println("message: delve started")

	// read delve output

	go func() {
		for {
			s, err := out.ReadString('\n')
			if err != nil {
				log.Println("read loop error", err)
				break
			}

			if strings.Contains(s, "[93m") {
				continue
			}

			if strings.Contains(s, "PC: ") {
				cc := strings.Split(s, " ")
				for _, ss := range cc {
					if strings.Contains(ss, ".go:") {
						fmt.Println("command: open", ss)
					}
				}
			} else {
				if dcommand != "next" && dcommand != "stepout" && dcommand != "step" {
					s = strings.ReplaceAll(s, "(dlv) ", "")
					log.Print(s)
				}
			}
			fmt.Println("reload: log")
		}
	}()

	// read user input and send to delve

	for {
		dcommand, err = in.ReadString('\n')
		if err != nil {
			log.Println("read user command:", err)
			break
		}
		dcommand = strings.TrimSpace(dcommand)
		_, err = stdin.Write([]byte(dcommand + "\n"))
		log.Println(">>", dcommand)
		fmt.Println("reload: log")
		if dcommand == "q" {
			log.Println("quit")
			break
		}
		if err != nil {
			log.Println("write command to dlv:", err)
			break
		}
	}

	if err := cmd.Process.Kill(); err != nil {
		log.Println("cannot send kill singal:", err)
	}

	log.Println("waiting dlv to stop")
	if err := cmd.Wait(); err != nil {
		fmt.Println("error: delve error: ", err.Error())
		log.Fatal(err)
	}
	log.Println("dlv stopped")
}

func initLog() (io.Closer, error) {
	log.SetFlags(0)

	const fname = "/tmp/delve-runner.log"

	lf, err := os.Create(fname)
	if err != nil {
		return nil, fmt.Errorf("create file %s: %w", fname, err)
	}

	log.SetOutput(lf)

	return lf, nil
}
