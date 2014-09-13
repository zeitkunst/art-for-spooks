#!/usr/bin/env python
import json
import string
import sys

import nltk

from optparse import *

# Markov chain generation modified from http://www.decontextualize.com/teaching/dwwp/topics-n-grams-and-markov-chains/

class MarkovGenerator(object):

    def __init__(self, order = 2):
        self.order = order
        self.ngrams = dict()
        self.words = []

    def tokenize(self, text):
        # Assuming that the incoming text is encoded as UTF-8
        text = unicode(text, "utf-8")
        tokenizer = nltk.tokenize.RegexpTokenizer(r'\w+|[^\w\s]+')
        return tokenizer.tokenize(text)

    def feed(self, text):
        tokens = self.tokenize(text)

        # Create a list of words that do not include punctuation
        # TODO
        # This is a bit brittle and can probably be better solved using a RE
        exclude = set(string.punctuation)
        punct = [",", ".", "!", "?", "(", ")", ";", "/", "\\"]
        for token in tokens:
            s = "".join(ch for ch in token if ch not in exclude)
            if s != "":
                self.words.append(token)

        for i in range(len(tokens) - self.order):
            gram = tuple(tokens[i:i+self.order])
            next_ngram = tokens[i + self.order]

            if gram in self.ngrams:
                self.ngrams[gram].append(unicode(next_ngram))
            else:
                self.ngrams[gram] = [unicode(next_ngram)]

    def get_ngrams(self):
        return self.ngrams

    def make_model_json(self):
        json_dict = {}
        model_dict = self.get_ngrams()
        model_keys = model_dict.keys()

        for key in model_keys:
            str_key = ""

            for token in key:
                str_key = "%s %s" % (str_key, token)
            
            str_key = str_key.strip()
            json_dict[str_key] = model_dict[key]

        return json.dumps(json_dict)

    def make_words_json(self):
        return json.dumps(self.words)

    def generate(self, num_words = 20, initial_word = "this"):
        from random import choice
    
        # Get all of the ngrams
        ngrams = self.get_ngrams().keys()

        # See if our initial word is in one of the ngrams
        word_ngrams = []
        for gram in ngrams:
            if initial_word in gram:
                word_ngrams.append(gram)
        
        if (len(word_ngrams) == 0):
            print "Initial word %s not found in ngrams, nothing to generate!", initial_word
            return ""

        # Set our fist ngram to a random selection of the ones that include our initial word
        current = choice(word_ngrams)
        output = list(current)

        for i in range(num_words):
            possible_next = self.ngrams[current]
            next_ngram = choice(possible_next)
            output.append(next_ngram)

            current = tuple(output[-self.order:])

        return " ".join(output)

if __name__ == "__main__":
    parser = OptionParser()

    parser.set_defaults(order=2)
    parser.add_option("-s", "--source", dest="source", help = "The file containing the corpus")
    parser.add_option("-d", "--order", dest="order", help = "The order of the Markov chain")
    parser.add_option("-o", "--output", dest="output", help = "Output stem of the generated json files")
    parser.add_option("-g", "--generate", dest="generate", action="store_true", help = "Generate a sample text of 50 words")

    options, args = parser.parse_args()

    if options.source is None:
        print "Source text must be specified"
        sys.exit(-1)

    mg = MarkovGenerator(order = int(options.order))

    with open(options.source, "r") as f:
        lines = f.readlines()
        text = "".join(lines)

    mg.feed(text)

    if (options.generate):
        generated_text = mg.generate(num_words = 50)
        print generated_text

    if (options.output is not None):
        model_json = mg.make_model_json()
        words_json = mg.make_words_json()

        with open("%s_model.json" % options.output, "w") as f:
            f.write(model_json)

        with open("%s_words.json" % options.output, "w") as f:
            f.write(words_json)
